from fastapi import FastAPI, Request, Form
from fastapi.templating import Jinja2Templates
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import yt_dlp
import whisper
import openai
import os
from dotenv import load_dotenv
from datetime import datetime
from supabase import create_client, Client
import uuid
import logging

# ロギングの設定
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 環境変数の読み込み
load_dotenv()

# FastAPIアプリケーションの設定
app = FastAPI(
    title="YouTube Transcriber API",
    description="YouTube動画の文字起こしと翻訳を行うAPI",
    version="1.0.0",
    debug=True
)

# CORSミドルウェアの設定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Supabaseクライアントの初期化
supabase: Client = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_KEY")
)

# テンプレートの設定
templates = Jinja2Templates(directory="templates")

# OpenAI APIキーの設定
openai.api_key = os.getenv('OPENAI_API_KEY')

# yt-dlpの設定
ydl_opts = {
    'format': 'best',
    'outtmpl': 'downloads/%(id)s.%(ext)s',
    'keepvideo': True
}

# Whisperモデルの読み込み
model = whisper.load_model("base")

# 静的ファイルの設定
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up application...")
    logger.info(f"SUPABASE_URL: {os.getenv('SUPABASE_URL')}")
    logger.info("Checking database connection...")
    try:
        response = supabase.table('videos').select('count', count='exact').execute()
        logger.info(f"Database connection successful. Found {response.count} videos.")
    except Exception as e:
        logger.error(f"Database connection failed: {str(e)}")

async def save_to_supabase(video_id: str, url: str, video_path: str, transcription: str, translation: str):
    """Supabaseにデータを保存する"""
    # 動画ファイルをStorageにアップロード
    with open(video_path, 'rb') as f:
        storage_path = f"videos/{video_id}/{os.path.basename(video_path)}"
        supabase.storage.from_('videos').upload(
            storage_path,
            f
        )

    # データベースに情報を保存
    data = {
        'youtube_url': url,
        'youtube_id': video_id,
        'video_path': storage_path,
        'transcription': transcription,
        'translation': translation
    }
    
    result = supabase.table('videos').insert(data).execute()
    return result.data

def save_to_markdown(video_id: str, url: str, transcription: str, translation: str):
    """結果をMarkdownファイルとして保存する"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"outputs/{video_id}_{timestamp}.md"
    
    content = f"""# YouTube 文字起こし & 翻訳結果

## 元動画情報
- URL: {url}
- 処理日時: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## 文字起こし結果
{transcription}

## 英訳結果
{translation}
"""
    
    os.makedirs('outputs', exist_ok=True)
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return filename

@app.get("/")
async def root(request: Request):
    try:
        recent_results = supabase.table('videos').select('*').order('created_at', desc=True).limit(5).execute()
        return templates.TemplateResponse("index.html", {
            "request": request,
            "recent_results": recent_results.data
        })
    except Exception as e:
        logger.error(f"Error in root route: {str(e)}")
        return JSONResponse({
            'success': False,
            'error': str(e)
        })

@app.post("/process")
async def process_video(youtube_url: str = Form(...)):
    try:
        # YouTubeからの動画ダウンロード
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(youtube_url, download=True)
            video_id = info['id']
            video_path = f"downloads/{video_id}.{info['ext']}"
            audio_file = f"downloads/{video_id}.mp3"

        # Whisperによる文字起こし
        result = model.transcribe(audio_file)
        transcription = result["text"]

        # OpenAI APIによる英訳
        response = openai.chat.completions.create(
            model="o3-mini",
            messages=[
                {"role": "system", "content": "Translate the following Japanese text to English:"},
                {"role": "user", "content": transcription}
            ]
        )
        translation = response.choices[0].message.content

        # Supabaseに保存
        await save_to_supabase(video_id, youtube_url, video_path, transcription, translation)

        # Markdownファイルとして保存
        md_file = save_to_markdown(video_id, youtube_url, transcription, translation)

        # 音声ファイルの削除（動画は保持）
        os.remove(audio_file)

        return JSONResponse({
            'success': True,
            'transcription': transcription,
            'translation': translation,
            'markdown_file': md_file
        })

    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        })

# APIルートの設定
from fastapi import APIRouter
router = APIRouter(prefix="/api")

@router.get("/videos")
async def get_videos():
    try:
        logger.info("Fetching all videos")
        response = supabase.table('videos').select('*').order('created_at', desc=True).execute()
        return JSONResponse({
            'success': True,
            'videos': response.data
        })
    except Exception as e:
        logger.error(f"Error fetching videos: {str(e)}")
        return JSONResponse({
            'success': False,
            'error': str(e)
        })

@router.get("/videos/{youtube_id}")
async def get_video(youtube_id: str):
    try:
        response = supabase.table('videos').select('*').eq('youtube_id', youtube_id).single().execute()
        return JSONResponse({
            'success': True,
            'video': response.data
        })
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        })

@router.get("/videos/{youtube_id}/full")
async def get_video_full(youtube_id: str):
    try:
        # 動画の基本情報を取得
        video = supabase.table('videos').select('*').eq('youtube_id', youtube_id).single().execute()
        
        # 関連するタグを取得
        tags = supabase.table('video_tags')\
            .select('tags(name)')\
            .eq('video_id', video.data['id'])\
            .execute()
        
        # 処理ログを取得
        logs = supabase.table('processing_logs')\
            .select('*')\
            .eq('video_id', video.data['id'])\
            .order('created_at', desc=True)\
            .execute()
        
        return JSONResponse({
            'success': True,
            'video': video.data,
            'tags': [tag['tags']['name'] for tag in tags.data],
            'logs': logs.data
        })
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        })

@router.get("/tags")
async def get_tags():
    try:
        response = supabase.table('tags').select('*').execute()
        return JSONResponse({
            'success': True,
            'tags': response.data
        })
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        })

# アプリケーション起動時にディレクトリを作成
os.makedirs('downloads', exist_ok=True)
os.makedirs('outputs', exist_ok=True)

# ルーターをアプリケーションに登録
app.include_router(router)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)