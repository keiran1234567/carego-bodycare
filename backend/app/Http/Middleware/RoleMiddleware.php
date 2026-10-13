<?php

namespace App\Http\Middleware;

use App\Http\Responses\ApiResponse;
use Closure;

class RoleMiddleware
{
    public function handle($request, Closure $next, ...$roles)
    {
        if (! $request->user() || ! $request->user()->isRole(...$roles)) {
            return ApiResponse::error('Anda tidak memiliki akses.', null, 403);
        }

        return $next($request);
    }
}
