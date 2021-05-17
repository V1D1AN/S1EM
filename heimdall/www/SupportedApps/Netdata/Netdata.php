<?php namespace App\SupportedApps\Netdata;

class Netdata extends \App\SupportedApps implements \App\EnhancedApps {
    private const ENDPOINT = 'api/v1/info';

    public $config;

    function __construct() {
    }

    public function test()
    {
        $test = parent::appTest($this->url(self::ENDPOINT));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url(self::ENDPOINT));
        $res = parent::execute($this->url(self::ENDPOINT));
        $details = json_decode($res->getBody());

        $data = [
            'count_warning' => $details->alarms->warning,
            'count_critical' => $details->alarms->critical
        ];

        return parent::getLiveStats($status, $data);
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
