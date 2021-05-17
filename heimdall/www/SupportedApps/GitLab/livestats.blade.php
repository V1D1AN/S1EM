<ul class="livestats">
    @isset($status)
    <li>
        <span class="title">Status</span>
        <strong>{!! $status !!}</strong>
    </li>
    @endisset
    @isset($count_projects)
    <li>
        <span class="title">Projects/<br />Users</span>
        <strong>{!! $count_projects !!} / {!! $count_users !!}</strong>
    </li>
    @endisset
</ul>