-- Enable necessary extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- Create videos table
create table public.videos (
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
create table public.tags (
    id uuid default uuid_generate_v4() primary key,
    name text not null unique,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create video_tags junction table
create table public.video_tags (
    video_id uuid references public.videos(id) on delete cascade,
    tag_id uuid references public.tags(id) on delete cascade,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    primary key (video_id, tag_id)
);

-- Create processing_logs table
create table public.processing_logs (
    id uuid default uuid_generate_v4() primary key,
    video_id uuid references public.videos(id) on delete cascade,
    step text not null check (step in ('download', 'transcription', 'translation')),
    status text not null check (status in ('started', 'completed', 'error')),
    message text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create updated_at function
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

-- Create updated_at trigger for videos table
create trigger handle_videos_updated_at
    before update on public.videos
    for each row
    execute function public.handle_updated_at();

-- Set up Storage
insert into storage.buckets (id, name, public)
values ('videos', 'videos', true)
on conflict (id) do nothing;

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

-- Storage policies
create policy "Videos are publicly accessible"
    on storage.objects for select
    using (bucket_id = 'videos');

create policy "Anyone can upload videos"
    on storage.objects for insert
    with check (bucket_id = 'videos'); 