<?php namespace App\SupportedApps\AriaNg;

class AriaNg extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    //protected $login_first = true; // Uncomment if api requests need to be authed first
    protected $method = 'POST';  // Uncomment if requests to the API should be set by POST

    function __construct() {
        $this->jar = new \GuzzleHttp\Cookie\CookieJar; // Uncomment if cookies need to be set
    }

    public function test()
    {
        $attrs = $this->newRequestAttrs('aria2.getVersion');
        $test = parent::appTest($this->url('jsonrpc'), $attrs);
        if ($test->code === 200) {
            $data = json_decode($test->response);
            if (isset($data->result) && isset($data->result->version)) {
                $version = $data->result->version;
                $test->status = "Connected to Aria2 v$version";
            }
            else {
                $test->status ="Unknown Aria2 version";
            }
        }
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $attrs = $this->newRequestAttrs('aria2.getGlobalStat');
        $res = parent::execute($this->url('jsonrpc'), $attrs);

        if ($res == null) {
            //Log::debug('Aria2 connection failed');
            return '';
        }

        $details = json_decode($res->getBody());
        if (!isset($details->result)) {
            //Log::debug('Failed to fetch data from Aria2');
            return '';
        }

        $downloadSpeed = $details->result->downloadSpeed;
        $uploadSpeed = $details->result->uploadSpeed;

        $active = $details->result->numActive;
        $stopped = $details->result->numStopped;
        $waiting = $details->result->numWaiting;

        if ($active > 0) {
            $status = 'active';
        }

        $data = [];
        $data['download_rate'] = format_bytes($downloadSpeed, false, ' <span>', '/s</span>');
        $data['upload_rate'] = format_bytes($uploadSpeed, false, ' <span>', '/s</span>');
        $data['running_count'] = ($active + $waiting) ?? 0;
        $data['stopped_count'] = $stopped ?? 0;

        return parent::getLiveStats($status, $data);
    }

    private function newRequestAttrs($rpcMethod)
    {
        $body = [
            'jsonrpc' => '2.0',
            'id' => 'qwer',
            'method' => $rpcMethod
        ];
        if (isset($this->config->password)) {
            $body['params'] = ['token:'.$this->config->password];
        }

        $attrs = [
            'body' => json_encode($body),
            'cookies' => $this->jar,
            'headers' => ['Content-Type' => 'application/json', 'Accept' => 'application/json']
        ];

        return $attrs;
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
