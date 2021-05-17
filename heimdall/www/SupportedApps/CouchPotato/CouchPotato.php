<?php namespace App\SupportedApps\CouchPotato;

class CouchPotato extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('app.available'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $data = [];

        $movies = json_decode(parent::execute($this->url('movie.list'))->getBody());
        $collect = collect($movies);
        $missing = $collect->whereNot('status', 'done');
        if($missing) {
          $data['missing'] = $missing->count() ?? 0;
        }

        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).'api/'.$this->config->apikey.'/'.$endpoint;
        return $api_url;
    }
}
