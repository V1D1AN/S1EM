<?php namespace App\SupportedApps\Miniflux;

class Miniflux extends \App\SupportedApps implements \App\EnhancedApps {
    private const ENDPOINT = 'v1/entries?status=unread';

    public $config;
    public $attrs = [];

    function __construct() {
    }

    private function setClientOptions() {
        if ($this->config->username != '' || $this->config->password != '') {
            $this->attrs = ['auth'=> [$this->config->username, $this->config->password]];
        }
    }

    public function test()
    {
        $this->setClientOptions();
        $test = parent::appTest($this->url(self::ENDPOINT), $this->attrs);
        echo $test->status;
    }

    public function livestats()
    {
        $this->setClientOptions();
        $res = parent::execute($this->url(self::ENDPOINT), $this->attrs);
        $details = json_decode($res->getBody());

        $data['count_unread'] = $details->total;
        return parent::getLiveStats('inactive', $data);
    }

    public function url($endpoint)
    {
        return parent::normaliseurl($this->config->url).$endpoint;
    }
}
