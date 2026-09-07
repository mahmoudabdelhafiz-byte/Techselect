<?php
return [
  'db' => [
    'host' => getenv('DB_HOST') ?: 'localhost',
    'name' => getenv('DB_NAME') ?: 'techselect',
    'user' => getenv('DB_USER') ?: 'techselect',
    'pass' => getenv('DB_PASS') ?: '',
    'charset' => 'utf8mb4',
  ],
  'site_url' => rtrim(getenv('SITE_URL') ?: 'https://techselectai.com', '/'),
  'openai_api_key' => getenv('OPENAI_API_KEY') ?: '',
  'openai_model' => getenv('OPENAI_MODEL') ?: 'gpt-5',
];
