<h2>{{ __('app.apps.config') }} ({{ __('app.optional') }}) @include('items.enable')</h2>
<div class="items">
    <div class="input">
        <label>{{ strtoupper(__('app.url')) }}</label>
        {!! Form::text('config[override_url]', (isset($item) ? $item->getconfig()->override_url : null), array('placeholder' => __('app.apps.override'), 'id' => 'override_url', 'class' => 'form-control')) !!}
    </div>
    <div class="input">
        <label>Service</label>
        {!! Form::text('config[service]', (isset($item) ? $item->getconfig()->service : 'jaeger-query'), array('placeholder' => 'Service, e.g. jaeger-query', 'data-config' => 'service', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <label>Operation</label>
        {!! Form::text('config[operation]', (isset($item) ? $item->getconfig()->operation : null), array('placeholder' => 'Operation, e.g. /api/traces', 'data-config' => 'operation', 'class' => 'form-control config-item')) !!}
    </div>
</div>
<div class="items">
    <div class="input">
        <label>{{ __('app.apps.tags') }}</label>
        {!! Form::text('config[tags]', (isset($item) ? $item->getconfig()->tags : null), array('placeholder' => __('app.apps.tags'), 'data-config' => 'tags', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <label>Lookback</label>
        {!! Form::select('config[lookback]', array('1h' => 'Last Hour', '2h' => 'Last 2 Hours', '3h' => 'Last 3 Hours', '6h' => 'Last 6 Hours', '12h' => 'Last 12 Hours', '24h' => 'Last 24 Hours', '2d' => 'Last 2 Days'), (isset($item) ? $item->getconfig()->lookback : null), array('data-config' => 'lookback', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <label>Limit</label>
        {!! Form::text('config[limit]', (isset($item) ? $item->getconfig()->limit : 100), array('placeholder' => 'Limit results', 'data-config' => 'limit', 'class' => 'form-control config-item')) !!}
    </div>
</div>
<div class="items">
    <div class="input">
        <label>Min Duration</label>
        {!! Form::text('config[minDuration]', (isset($item) ? $item->getconfig()->minDuration : null), array('placeholder' => 'e.g. 1.2s, 100ms, 500us', 'data-config' => 'minDuration', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <label>MaxDuration</label>
        {!! Form::text('config[maxDuration]', (isset($item) ? $item->getconfig()->maxDuration : null), array('placeholder' => 'e.g. 1.2s, 100ms, 500us', 'data-config' => 'maxDuration', 'class' => 'form-control config-item')) !!}
    </div>
    <div class="input">
        <button style="margin-top: 32px;" class="btn test" id="test_config">Test</button>
    </div>
</div>