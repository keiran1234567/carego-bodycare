<?php

return [
    'server_key' => env('MIDTRANS_SERVER_KEY'),
    'client_key' => env('MIDTRANS_CLIENT_KEY'),
    'is_production' => (bool) env('MIDTRANS_IS_PRODUCTION', false),
    'allow_local_fallback' => (bool) env('MIDTRANS_ALLOW_LOCAL_FALLBACK', false),
];
