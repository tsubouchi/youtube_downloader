-- Insert sample tags
insert into public.tags (name) values
    ('programming'),
    ('tutorial'),
    ('music'),
    ('education'),
    ('technology')
on conflict (name) do nothing;

-- Insert sample videos
insert into public.videos (
    youtube_url,
    youtube_id,
    title,
    description,
    status,
    transcription,
    translation
) values
(
    'https://www.youtube.com/watch?v=sample1',
    'sample1',
    'プログラミング入門講座',
    'プログラミングの基礎を学ぶ動画です。',
    'completed',
    'こんにちは、今日はプログラミングの基礎について説明します。',
    'Hello, today I will explain the basics of programming.'
),
(
    'https://www.youtube.com/watch?v=sample2',
    'sample2',
    'Tech News 2024',
    '最新のテクノロジーニュースをお届けします。',
    'completed',
    '今日は2024年の最新テクノロジートレンドについて解説します。',
    'Today, I will explain the latest technology trends in 2024.'
)
on conflict (youtube_id) do update set
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    status = EXCLUDED.status,
    transcription = EXCLUDED.transcription,
    translation = EXCLUDED.translation;

-- Clean up existing video tags before inserting new ones
delete from public.video_tags
where video_id in (
    select id from public.videos where youtube_id in ('sample1', 'sample2')
);

-- Link videos with tags
insert into public.video_tags (
    video_id,
    tag_id
)
select 
    v.id as video_id,
    t.id as tag_id
from public.videos v
cross join public.tags t
where v.youtube_id = 'sample1'
    and t.name in ('programming', 'education', 'tutorial');

insert into public.video_tags (
    video_id,
    tag_id
)
select 
    v.id as video_id,
    t.id as tag_id
from public.videos v
cross join public.tags t
where v.youtube_id = 'sample2'
    and t.name in ('technology');

-- Clean up existing processing logs before inserting new ones
delete from public.processing_logs
where video_id in (
    select id from public.videos where youtube_id in ('sample1', 'sample2')
);

-- Insert sample processing logs
insert into public.processing_logs (
    video_id,
    step,
    status,
    message
)
select 
    v.id as video_id,
    step.name as step,
    'completed' as status,
    'Successfully processed' as message
from public.videos v
cross join (
    values 
        ('download'),
        ('transcription'),
        ('translation')
) as step(name)
where v.status = 'completed'; 