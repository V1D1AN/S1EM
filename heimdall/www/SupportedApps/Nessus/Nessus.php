<?php namespace App\SupportedApps\Nessus;

class Nessus extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;
    private $clientVars = [
        'http_errors' => false, 
        'timeout' => 15, 
        'connect_timeout' => 15,
        'verify' => false,
    ];
    
    function __construct() {
    }

    private function acquireToken()
    {
        $username = $this->config->username;
        $password = $this->config->password;
        $attrs = [
            'body' => json_encode(array('username' => $username, 'password' => $password)),
            'headers' => ['content-type' => 'application/json']
        ];
        $res = parent::execute($this->url('session'), $attrs, $this->clientVars, 'POST');
        switch ($res->getStatusCode()) {
            case 200: 
                $details = json_decode($res->getBody());
                return $details->token;
            case 400:
                throw new \Exception("Invalid username format");
            case 401:
                throw new \Exception("Invalid username/password");
        }

        throw new \Exception("Error connecting to Nessus");
    }

    public function test()
    {
        try {
            $this->acquireToken();
        } catch (\Throwable $e) {
            echo $e->getMessage();
            return;
        }
        echo 'Successfully communicated with the API';
    }

    public function livestats()
    {
        $token = $this->acquireToken();
        $status = 'inactive';
        $attrs = [
            'headers' => ['X-Cookie' => 'token='.$token]
        ];
        $res = parent::execute($this->url('scans'), $attrs, $this->clientVars);
        $details = json_decode($res->getBody());
        $data = [];
        if ($details && !isset($details->error)) {
            foreach ($details->scans as $scan) {
                if ($scan->status == "running") {
                    $data['scanner'] = $scan->name;
                    $status = 'active';
                    break;
                }
            }
        }
        return parent::getLiveStats($status, $data);
        
    }
    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}
