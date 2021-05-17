<?php namespace App\SupportedApps\Bookstack;

class Bookstack extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function getHeaders()
    {
        $api_token = $this->config->api_token.":".$this->config->api_secret;

        $attrs['headers'] = ['Authorization' => 'Token '.$api_token];
        return $attrs;
    }

    public function test()
    {
        $test = parent::appTest($this->url('/api/shelves?count=0'), $this->getHeaders());
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';

        $attrs = $this->getHeaders();

        $data = ['visiblestats' => []];

        foreach($this->config->availablestats as $stat) {
            if (!isset(self::getAvailableStats()[$stat])) continue;

            $res = parent::execute($this->url('/api/'.$stat.'?count=0'), $attrs);
            $details = json_decode($res->getBody());

            $newstat = new \stdClass();
            $newstat->title = self::getAvailableStats()[$stat];
            $newstat->value = isset($details->total) ? number_format($details->total) : 'N/A';

            $data['visiblestats'][] = $newstat;
        }

        return parent::getLiveStats($status, $data);
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }

    public static function getAvailableStats() {
        return [
            'shelves'=>'Shelves',
            'books'=>'Books',
            'chapters'=>'Chapters',
        ];
    }
}
