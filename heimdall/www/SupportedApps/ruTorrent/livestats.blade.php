<ul class="livestats">
    @if($down_rate != "0 B/s")
    <li style="width:50%;">
        <span class="title">DOWN ↓</span>
        <strong>{!! $down_rate !!}</strong>
    </li>
    @endif
    @if($up_rate != "0 B/s")
    <li>
        <span class="title">UP ↑</span>
        <strong>{!! $up_rate !!}</strong>
    </li>
    @endif
</ul>
