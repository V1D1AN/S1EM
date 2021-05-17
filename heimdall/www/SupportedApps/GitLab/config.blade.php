<h2>{{ __('app.apps.config') }} ({{ __('app.optional') }}) @include('items.enable')</h2>
<h5>{{ __('app.apps.only_admin_account') }}</h5>
<div class="items">
    <div class="input">
        <label>Health Token</label>
        <small>Admin Area &raquo; Monitoring &raquo; Health Check</small>
        {!! Form::text('config[health_apikey]', null, array('placeholder' => 'Health Token', 'id' => 'health_apikey', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <label>Private API-Read Token</label>
        <small>User Settings &raquo; Access Tokens</small>
        {!! Form::text('config[private_apikey]', null, array('placeholder' => __('app.apps.apikey'), 'id' => 'private_apikey', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <button style="margin-top: 32px;" class="btn test" id="test_config">Test</button>
    </div>
</div>

