<?php namespace App\SupportedApps\Plex;

class Plex extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        //$this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('/library/recentlyAdded'));
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('/library/recentlyAdded'));

        $body = $res->getBody();
        $xml = simplexml_load_string($body, 'SimpleXMLElement', LIBXML_NOCDATA | LIBXML_NOBLANKS);
        $data = [];
        if($xml) {
            $data['recently_added'] = $xml['size'];
            $status = 'active';
        }

        $res = parent::execute($this->url('/library/onDeck'));

        $body = $res->getBody();
        $xml = simplexml_load_string($body, 'SimpleXMLElement', LIBXML_NOCDATA | LIBXML_NOBLANKS);
        if($xml) {
            $data['on_deck'] = $xml['size'];
            $status = 'active';
        }

        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $url = parse_url(parent::normaliseurl($this->config->url));
        $domain = $url['host'];
        $api_url = "http://".$domain.":32400".$endpoint."?X-Plex-Token=".$this->config->token;
        return $api_url;
    }
}