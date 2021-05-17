<?php namespace App\SupportedApps\FreshRSS;

class FreshRSS extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    function __construct() 
    {
       
    }

    private $clientVars = [
        'http_errors' => false, 
        'timeout' => 15, 
        'connect_timeout' => 15,
        'verify' => false,
    ];

    public function test()
    {
        $attrs = [
            'body' => 'api_key='.$this->getApiKey(),
            'headers' => ['Content-Type' => 'application/x-www-form-urlencoded']
        ];
        
        $res = parent::execute($this->url('api/fever.php?api'), $attrs, $this->clientVars, 'POST');
        
        if($res->getStatusCode() == 200) {
            $data = json_decode($res->getBody());
            if($data != null && $data->auth === 1){
                echo "Welcome " . $this->config->username . ", you are connected to API v".$data->api_version;
            }
        }
    }

    public function livestats()
    {
        $status = 'inactive';
        $data = [];

        $attrs = [
            'body' => 'api_key='.$this->getApiKey(),
            'headers' => ['Content-Type' => 'application/x-www-form-urlencoded']
        ];
        
        $res = parent::execute($this->url('api/fever.php?api&unread_item_ids'), $attrs, $this->clientVars, 'POST');
        if($res->getStatusCode() == 200) {
            $body = json_decode($res->getBody());
			if($body->auth === 1){
				if($body->unread_item_ids != ""){
					$data['unread'] = count(explode(",", $body->unread_item_ids));
				} else{
					$data['unread'] = 0;
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
    
    public function getApiKey()
    {
        return md5($this->config->username.":".$this->config->apikey);
    }
}