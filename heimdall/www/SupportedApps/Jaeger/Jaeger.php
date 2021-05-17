<?php namespace App\SupportedApps\Jaeger;

class Jaeger extends \App\SupportedApps implements \App\EnhancedApps {

    public $config;

    function __construct() {
    }

    private function tracesUrl() {
        $service = $this->config->service;
        $operation = $this->config->operation;
        $tags = $this->config->tags;
        $lookback = $this->config->lookback;
        $minDuration = $this->config->minDuration;
        $maxDuration = $this->config->maxDuration;
        $limit = $this->config->limit;
        
        $endpoint = 'api/traces?service='.urlencode($service);
        if (!empty($operation)) $endpoint .= '&operation='.urlencode($operation);
        if (!empty($tags)) $endpoint .= '&tags='. urlencode($tags);
        if (!empty($lookback)) {
            $lookbackFormatted = str_replace('d', ' days', str_replace('h', ' hours', $lookback));
            $timestampForOffset = time();
            $offset = $timestampForOffset - strtotime('-'.$lookbackFormatted, $timestampForOffset);

            $timestamp = microtime(true);
            $end = sprintf('%0.0f', $timestamp * 1000000);
            $start = sprintf('%0.0f', ($timestamp - $offset) * 1000000);
            $endpoint .= '&lookback='.urlencode($lookback);
            $endpoint .= '&start='.$start;
            $endpoint .= '&end='.$end;
        }
        if (!empty($minDuration)) $endpoint .= '&minDuration='.urlencode($minDuration);
        if (!empty($maxDuration)) $endpoint .= '&maxDuration='.urlencode($maxDuration);
        if (!empty($limit)) $endpoint .= '&limit='.urlencode($limit);
        return $this->url($endpoint);
    }

    public function test()
    {
        $test = parent::appTest($this->tracesUrl());
        echo $test->status;
    }

    public function livestats()
    {
        $status = 'inactive';
        $res = parent::execute($this->tracesUrl());
        $details = json_decode($res->getBody());

        $data = [];

        if($details) {
            $status = 'active';
            $data['traces'] = count($details->data);
            $data['avg_duration'] = 0;
            if ($data['traces'] > 0) {
                $durations = array_map(function($dataItem) {
                    $max = 0;
                    foreach ($dataItem->spans as $spanItem) {
                        $max = max($max, $spanItem->duration);
                    } 
                    return $max;
                }, $details->data);
                $data['avg_duration'] = round(array_sum($durations)/$data['traces']/1000, 1);
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
