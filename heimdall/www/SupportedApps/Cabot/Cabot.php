<?php namespace App\SupportedApps\Cabot;

class Cabot extends \App\SupportedApps implements \App\EnhancedApps {
    private const ENDPOINT = 'api/services/?format=json';

    private const STATUS_PASSING = 'Passing';
    private const STATUS_WARNING = 'Warning';
    private const STATUS_ERROR = 'Error';
    private const STATUS_CRITICAL = 'Critical';

    public $config;

    public function test()
    {
        $test = parent::appTest($this->url(self::ENDPOINT));
        echo $test->status;
    }

    public function livestats()
    {
        $result = parent::execute($this->url(self::ENDPOINT));
        $services = json_decode($result->getBody());

        $results = [
            self::STATUS_PASSING => 0,
            self::STATUS_WARNING => 0,
            self::STATUS_ERROR => 0,
            self::STATUS_CRITICAL => 0,
        ];

        foreach ($services as $service) {
            $overallStatus = ucfirst(strtolower($service->overall_status ?? ''));

            if (isset($results[$overallStatus])) {
                $results[$overallStatus]++;
            }
        }

        if ($results[self::STATUS_CRITICAL] > 0) {
            $status = self::STATUS_CRITICAL;
        } elseif ($results[self::STATUS_ERROR] > 0) {
            $status = self::STATUS_ERROR;
        } elseif ($results[self::STATUS_WARNING] > 0) {
            $status = self::STATUS_WARNING;
        } else {
            $status = self::STATUS_PASSING;
        }

        $data['status_output'] = $status;
        $data['count_output'] = $results[$status];

        return parent::getLiveStats('inactive', $data);
    }

    public function url($endpoint)
    {
        $api_url = parent::normaliseurl($this->config->url).$endpoint;
        return $api_url;
    }
}