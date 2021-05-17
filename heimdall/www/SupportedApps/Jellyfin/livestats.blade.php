<ul class="livestats">
    @foreach ($visiblestats as $stat)
    <li>
        <span class="title">{!! $stat->title !!}</span>
        <strong>{!! $stat->value !!}</strong>
    </li>
    @endforeach
</ul>
