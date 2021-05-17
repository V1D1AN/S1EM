<?php namespace App\SupportedApps\Jackett;

class Jackett extends \App\SupportedApps implements \App\SearchInterface {
    public $type = 'external'; // Whether to go to the external site or display results locally
    public function getResults($query, $provider)
    {
        $url = rtrim($provider->url, '/');
        $q = urlencode($query);
        return redirect($url.'#search='.$q);
    }
}
