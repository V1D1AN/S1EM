<h2>{{ __('app.apps.config') }} ({{ __('app.optional') }}) @include('items.enable')</h2>
<div class="items">
    <div class="input">
        <label>{{ strtoupper(__('app.url')) }}</label>
        {!! Form::text('config[override_url]', (isset($item) ? $item->getconfig()->override_url : null), array('placeholder' => __('app.apps.override'), 'id' => 'override_url', 'class' => 'form-control')) !!}
    </div>
    <div class="input">
        <label>{{ __('app.apps.username') }}</label>
        {!! Form::text('config[username]', (isset($item) ? $item->getconfig()->username : null), array('placeholder' => __('app.apps.username'), 'data-config' => 'username', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <label title="You need a passhash not a password, you can find this on the User Account page in PRTG.">Passhash (help?)</label>
        {!! Form::text('config[passhash]', (isset($item) ? $item->getconfig()->passhash : null), array('placeholder' => __('Passhash'), 'data-config' => 'passhash', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <button style="margin-top: 32px;" class="btn test" id="test_config">Test</button>
    </div>
</div>
