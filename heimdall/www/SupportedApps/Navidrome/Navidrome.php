<?php namespace App\SupportedApps\Navidrome;

class Navidrome extends \App\SupportedApps implements \App\EnhancedApps
{
    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct()
    {
        // $this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = parent::appTest($this->url('rest/ping'), $this->getAttributes());
        if ($test->code === 200) {
            $result = json_decode($test->response);
            if ($result->{'subsonic-response'}->status != 'ok') {
                $test->status = $result->{'subsonic-response'}->error->message;
            }
        }
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->url('rest/getNowPlaying'), $this->getAttributes());
        $result = json_decode($res->getBody(), true);

        $data['now_playing'] = !$result['subsonic-response']['nowPlaying'] ? 0 : count($result['subsonic-response']['nowPlaying']);
        return parent::getLiveStats($status, $data);
    }

    private function getAttributes()
    {
        $salt = 'omHQfVJ';
        $authToken = md5($this->config->password . $salt);
        return [
            'query' => [
                'u' => $this->config->username,     // username
                't' => $authToken,                  // token
                's' => $salt,                       // salt
                'v' => '1.16.1',                    // subsonic API version
                'c' => 'heimdall',                  // client name
                'f' => 'json',                      // request data format
            ]
        ];
    }

    public function url($endpoint)
    {
        $apiUrl = parent::normaliseurl($this->config->url) . $endpoint;
        return $apiUrl;
    }
}
