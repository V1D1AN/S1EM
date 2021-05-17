<h2>{{ __('app.apps.config') }} ({{ __('app.optional') }}) @include('items.enable')</h2>
<div class="items">
    {!! Form::hidden('config[override_url]') !!}
    {!! Form::hidden('config[password]') !!}
    <div class="input">
        <label>{{ __('app.apps.api_token') }}</label>
        {!! Form::text('config[username]', (isset($item) ? $item->getconfig()->username : null), array('placeholder' => __('app.apps.username'), 'data-config' => 'username', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <button style="margin-top: 32px;" class="btn test" id="test_config">Test</button>
    </div>
</div>

