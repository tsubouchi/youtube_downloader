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
# Web フレームワーク
fastapi==0.109.2
uvicorn==0.27.1

# 環境変数
python-dotenv>=1.0.1

# ファイルアップロード
python-multipart==0.0.7

# YouTube動画ダウンロード
pytube==15.0.0
yt-dlp==2025.1.26

# HTTP通信
requests==2.32.3
aiohttp==3.11.12

# データベース
supabase==2.13.0

# S3ストレージ
boto3==1.36.16

# VercelへのDeploy
bash
vercel deploy

Production: https://youtube-downloader-hecqo81g1-bonginkan-projects.vercel.app