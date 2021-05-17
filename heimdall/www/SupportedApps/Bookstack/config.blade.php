<h2>{{ __('app.apps.config') }} ({{ __('app.optional') }}) @include('items.enable')</h2>
<div class="items">
    <div class="input">
        <label>{{ strtoupper(__('app.url')) }}</label>
        {!! Form::text('config[override_url]', isset($item) ? ($item->getConfig()->override_url ?? null) : null, array('placeholder' => __('app.apps.override'), 'id' => 'override_url', 'class' => 'form-control')) !!}
    </div>
    <div class="input">
        <label>Token ID</label>
        {!! Form::text('config[api_token]', null, array('placeholder' => 'Token ID', 'data-config' => 'api_token', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <label>Token Secret</label>
        {!! Form::text('config[api_secret]', null, array('placeholder' => 'Token Secret', 'data-config' => 'api_secret', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <label>Stats to show</label>
        {!! Form::select('config[availablestats][]', App\SupportedApps\Bookstack\Bookstack::getAvailableStats(), isset($item) ? ($item->getConfig()->availablestats ?? null) : null, array('multiple'=>'multiple')) !!}
    </div>
    <div class="input">
        <button style="margin-top: 32px;" class="btn test" id="test_config">Test</button>
    </div>
</div>

