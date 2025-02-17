-- Enable necessary extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- Create videos table
create table if not exists public.videos (
    id uuid default uuid_generate_v4() primary key,
    youtube_url text not null,
    youtube_id text not null unique,
    title text,
    description text,
    video_path text,
    transcription text,
    translation text,
    duration integer,
    thumbnail_url text,
    status text default 'pending' check (status in ('pending', 'processing', 'completed', 'error')),
    error_message text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create tags table
create table if not exists public.tags (
    id uuid default uuid_generate_v4() primary key,
    name text not null unique,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create video_tags junction table
create table if not exists public.video_tags (
    video_id uuid references public.videos(id) on delete cascade,
    tag_id uuid references public.tags(id) on delete cascade,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    primary key (video_id, tag_id)
);

-- Create processing_logs table
create table if not exists public.processing_logs (
    id uuid default uuid_generate_v4() primary key,
    video_id uuid references public.videos(id) on delete cascade,
    step text not null check (step in ('download', 'transcription', 'translation')),
    status text not null check (status in ('started', 'completed', 'error')),
    message text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Set up RLS (Row Level Security)
alter table public.videos enable row level security;
alter table public.tags enable row level security;
alter table public.video_tags enable row level security;
alter table public.processing_logs enable row level security;

-- Create policies
create policy "Videos are viewable by everyone"
    on public.videos for select
    using (true);

create policy "Videos can be inserted by anyone"
    on public.videos for insert
    with check (true);

create policy "Tags are viewable by everyone"
    on public.tags for select
    using (true);

create policy "Video tags are viewable by everyone"
    on public.video_tags for select
    using (true);

create policy "Processing logs are viewable by everyone"
    on public.processing_logs for select
    using (true); 