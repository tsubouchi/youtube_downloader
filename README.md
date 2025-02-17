# YouTube Transcriber

YouTubeの動画から文字起こしと翻訳を行うWebアプリケーション

![メイン画面](images/main.png)

## 機能

- YouTube動画のダウンロード
- 音声の文字起こし（Whisper AI）
- 日本語から英語への翻訳（OpenAI API）
- 結果の保存とMarkdownファイル出力
- タグ付けと検索機能

## セットアップ

1. 必要なパッケージのインストール：
bash
pip install -r requirements.txt

env
OPENAI_API_KEY=your_openai_api_key
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_KEY=your_supabase_anon_key

4. アプリケーションの起動：
bash
uvicorn app:app --reload --port 8001


## 使用方法

1. ブラウザで`http://localhost:8001`にアクセス
2. YouTube URLを入力
3. 「処理開始」をクリック
4. 文字起こしと翻訳結果が表示される

## API エンドポイント

- `GET /api/videos` - 全ての動画リストを取得
- `GET /api/videos/{youtube_id}` - 特定の動画の情報を取得
- `GET /api/videos/{youtube_id}/full` - 動画の詳細情報（タグ、ログを含む）を取得
- `GET /api/tags` - 全てのタグを取得
- `POST /process` - 新しい動画を処理

## 技術スタック

- FastAPI
- Supabase
- Whisper AI
- OpenAI API
- yt-dlp

requirements.txtの更新：
fastapi==0.109.2
uvicorn==0.27.1
python-dotenv==1.0.1
openai==1.12.0
yt-dlp==2023.12.30
whisper==1.1.10
supabase==2.3.1
python-multipart==0.0.7
jinja2==3.1.3
httpx==0.26.0