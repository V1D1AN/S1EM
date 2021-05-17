<?php namespace App\SupportedApps\Bazarr;

class Bazarr extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $attrs = [
            'headers'  => ['Accept' => 'application/json']
        ];
        $test = parent::appTest($this->url('systemstatus'), $attrs);
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $data = [];
        $attrs = [
            'headers'  => ['Accept' => 'application/json']
        ];
        
        
        $movies = json_decode(parent::execute($this->url('badges_movies'), $attrs)->getBody());
        $series = json_decode(parent::execute($this->url('badges_series'), $attrs)->getBody());

        $data = [];

        if($movies || $series) {
            $data['movies'] = $movies->missing_movies ?? 0;
            $data['series'] = $series->missing_episodes ?? 0;
        }

        return parent::getLiveStats($status, $data);
        
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).'api/'.$endpoint.'?apikey='.$this->config->apikey;
        return $api_url;
    }
}
