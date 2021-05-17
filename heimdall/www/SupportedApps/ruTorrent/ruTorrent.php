<?php namespace App\SupportedApps\ruTorrent;

use GuzzleHttp\Exception\RequestException;

class ruTorrent extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    function __construct() 
    {
    }

    public function test()
    {
        $data = $this->getXMLRPCData('throttle.global_down.rate');
        if( !isset($data) || $data == 'Err' || $data == null || !is_object($data))
        {
           echo 'There is an issue connecting to "' . $this->url('RPC2') . '". Please respect URL format "http(s)://IP:PORT". ' . $data;
        }
        else
        {
           echo 'Connection successful!';
        }
    }

    public function livestats()
    {
        $status = 'inactive';

        $data = [];
        $data['down_rate'] = $this->formatBytes((float)$this->getXMLRPCData('throttle.global_down.rate')->params->param->value->i8, 1);

        $data['up_rate'] = $this->formatBytes((float)$this->getXMLRPCData('throttle.global_up.rate')->params->param->value->i8, 1);

        return parent::getLiveStats($status, $data);
    }

    public function url($endpoint)
    {
        return parent::normaliseurl($this->config->url).$endpoint;
    }

    public function getXMLRPCData($method)
    {
        $value='';

        $body = '<methodCall><methodName>'.$method.'</methodName></methodCall>';

        $this->vars = ['http_errors' => false, 'timeout' => 5, 'body' => $body];
        $this->attrs = [];
        $this->attrs['headers'] = ['Content-Type' => 'text/xml'];

        if( isset($this->config->username) && isset($this->config->password) ) {
            $this->attrs['headers']['Authorization'] = 'Basic ' . base64_encode($this->config->username . ":" . $this->config->password);
        }

        try{
            $res = parent::execute($this->url('RPC2'), $this->attrs, $this->vars);
        } catch(\GuzzleHttp\Exception\RequestException $e){
            return ''; // Connection failed, display default response
        }

        if (function_exists('simplexml_load_string')) {
            try {
                $value = simplexml_load_string($res->getBody()->getContents());
            } catch(\ErrorException $e) {
                $value = 'Unexpected response. Are credentials correct?';
            }
        } else {
            $value = 'simplexml_load_string doesn\'t exist.';
        }

        return $value;
    }

    public function formatBytes($bytes, $precision = 2) 
    {
        $units = array('B', 'KB', 'MB', 'GB', 'TB'); 

        $bytes = max($bytes, 0);
        $pow = floor(($bytes ? log($bytes) : 0) / log(1024)); 
        $pow = min($pow, count($units) - 1); 

        $bytes /= pow(1024, $pow); 

        return round($bytes, $precision) . ' ' . $units[$pow] . '/s';
    }
}
