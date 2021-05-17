<?php namespace App\SupportedApps\qBittorrent;

# qBitTorrent v4.2.0 onwards enforces the use of API v2.
# API Documentation:
# https://github.com/qbittorrent/qBittorrent/wiki/Web-API-Documentation#authentication

class qBittorrent extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    //protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        $this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $test = $this->login();
        if($test->getStatusCode() === 200) {
            echo $test->getStatusCode();
        }
        #$test = parent::appTest($this->url('version/api'));
        $test = parent::appTest($this->url('api/v2/app/version'));
        echo $test->status;
    }

    public function login()
    {
        $username = urlencode($this->config->username);
        $password = urlencode($this->config->password);
        $attrs = [
            'body' => 'username='.$username.'&password='.$password,
            'cookies' => $this->jar,
            'headers' => ['content-type' => 'application/x-www-form-urlencoded']
        ];
        #return parent::execute($this->url('login'), $attrs, false, 'POST');
        return parent::execute($this->url('api/v2/auth/login'), $attrs, false, 'POST');
    }

    public function livestats()
    {
        $status = 'inactive';
        $this->login();
        $attrs = [
                'cookies' => $this->jar
        ];
        #$res = parent::execute($this->url('query/torrents'), $attrs);
        $res = parent::execute($this->url('api/v2/torrents/info'), $attrs);
        $details = json_decode($res->getBody());

        $data = [];


        $torrents = $details;
        $torrentCount = count($torrents);
        $rateDownload = $rateUpload = $completedTorrents = 0;
        foreach ($torrents as $thisTorrent) {
            $rateDownload += $thisTorrent->dlspeed;
            $rateUpload += $thisTorrent->upspeed;
            if ($thisTorrent->progress == 1) {
                $completedTorrents += 1;
            }
        }
        $leech = $torrentCount - $completedTorrents;
        if ($leech > 0) {
            $status = 'active';
        }

        $data['download_rate'] = format_bytes($rateDownload, false, ' <span>', '/s</span>');
        $data['upload_rate'] = format_bytes($rateUpload, false, ' <span>', '/s</span>');
        $data['seed_count'] = $completedTorrents ?? 0;
        $data['leech_count'] = $leech ?? 0;  




        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
