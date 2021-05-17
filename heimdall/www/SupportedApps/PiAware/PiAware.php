<?php namespace App\SupportedApps\PiAware;

class PiAware extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('data/aircraft.json'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('data/aircraft.json'));
        $details = json_decode($res->getBody(), true);

        $data = [];

        if($details) {
          $filtered_total = array_filter($details['aircraft'], function($element) {
              return $element['seen'] <= 58;
          });
          $data['total'] = count($filtered_total);
          $filtered_positions = array_filter($filtered_total, function($element) {
              return array_key_exists('seen_pos', $element) && $element['seen_pos'] < 60;
          });
          $data['positions'] = count($filtered_positions);
        }

        return parent::getLiveStats($status, $data);
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
