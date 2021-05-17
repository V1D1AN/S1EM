<ul class="livestats flexcolumn">
    <li>
        @if(strlen($artist) > 12)
        <div class="title-marquee"><span><span class="title">Artist</span>{!! $artist !!}</span></div>
        @else
        <div class="no-marquee"><span><span class="title">Artist</span>{!! $artist !!}</span></div>
        @endif
    </li>
    <li>
        @if(strlen($song_title) > 12)
        <div class="title-marquee"><span><span class="title">Song</span>{!! $song_title !!}</span></div>
        @else
        <div class="no-marquee"><span><span class="title">Song</span>{!! $song_title !!}</span></div>
        @endif
    </li>
</ul>