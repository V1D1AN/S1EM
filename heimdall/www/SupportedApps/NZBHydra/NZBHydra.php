<?php namespace App\SupportedApps\NZBHydra;

class NZBHydra extends \App\SupportedApps implements \App\SearchInterface {
    public $type = 'external'; // Whether to go to the external site or display results locally
    public function getResults($query, $provider)
    {
        $url = rtrim($provider->url, '/');
        $q = urlencode($query);
        return redirect($url.'/?category=All&mode=search&query='.$q);
    }
}
