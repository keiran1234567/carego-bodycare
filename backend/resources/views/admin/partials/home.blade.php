@php
    $lineValues = $charts['bookings']->values();
    $lineMax = max(1, $lineValues->max());
    $linePoints = $lineValues->map(fn ($value, $index) => ($index * (660 / max(1, $lineValues->count() - 1))).','. (190 - ($value / $lineMax * 155)))->implode(' ');
    $incomeMax = max(1, $charts['income']->max());
    $popularTotal = max(1, $charts['popular']->sum('bookings_count'));
    $colors = ['#6953e8', '#2f83f7', '#2ebd72', '#ff8d3b', '#f35f9e'];
@endphp
<section class="hero-stats">
    @foreach([
        ['US','Total User',$stats['users'],'purple'],
        ['MI','Total Mitra',$stats['mitras'],'green-icon'],
        ['PE','Total Pelayan',$stats['pelayans'],'orange-icon'],
        ['BK','Total Booking',$stats['bookings'],'blue-icon'],
        ['RP','Total Pendapatan','Rp '.number_format($stats['revenue'],0,',','.'),'pink-icon']
    ] as $card)
    <article class="hero-card">
        <div class="hero-icon {{ $card[3] }}">{{ $card[0] }}</div>
        <div><span>{{ $card[1] }}</span><strong>{{ $card[2] }}</strong><small>Naik dari data sebelumnya</small></div>
    </article>
    @endforeach
</section>

<section class="dashboard-charts">
    <article class="modern-panel">
        <div class="modern-head"><h2>Booking per Bulan</h2><span>Tahun {{ now()->year }}</span></div>
        <div class="line-chart">
            <svg viewBox="0 0 660 210" preserveAspectRatio="none">
                <defs><linearGradient id="lineFill" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7257e8" stop-opacity=".24"/><stop offset="1" stop-color="#7257e8" stop-opacity="0"/></linearGradient></defs>
                @foreach([35,75,115,155,190] as $y)<line x1="0" y1="{{ $y }}" x2="660" y2="{{ $y }}" stroke="#e9eaf2" stroke-width="1"/>@endforeach
                <polygon points="0,190 {{ $linePoints }} 660,190" fill="url(#lineFill)"/>
                <polyline points="{{ $linePoints }}" fill="none" stroke="#6953e8" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
                @foreach($lineValues as $i=>$value)<circle cx="{{ $i * (660 / max(1,$lineValues->count()-1)) }}" cy="{{ 190-($value/$lineMax*155) }}" r="4" fill="#6953e8" stroke="white" stroke-width="2"/>@endforeach
            </svg>
            <div class="axis-labels">@foreach($charts['labels'] as $label)<span>{{ str($label)->before(' ') }}</span>@endforeach</div>
        </div>
    </article>
    <article class="modern-panel">
        <div class="modern-head"><h2>Pendapatan per Bulan</h2><span>Tahun {{ now()->year }}</span></div>
        <div class="income-chart">
            @foreach($charts['income'] as $i=>$value)
            <div class="income-col"><small>{{ $value ? number_format($value/1000,0).'k' : '' }}</small><div style="height:{{ max(4,$value/$incomeMax*170) }}px"></div><span>{{ str($charts['labels'][$i])->before(' ') }}</span></div>
            @endforeach
        </div>
    </article>
</section>

<section class="dashboard-lower">
    <article class="modern-panel">
        <div class="modern-head"><h2>Booking Hari Ini</h2><a href="{{ route('admin.dashboard',['section'=>'bookings']) }}">Lihat Semua</a></div>
        <table class="today-table"><thead><tr><th>ID Booking</th><th>User</th><th>Layanan</th><th>Mitra</th><th>Waktu</th><th>Status</th></tr></thead><tbody>
        @forelse($todayBookings as $booking)<tr><td>#{{ $booking->booking_code }}</td><td><b>{{ $booking->user?->name }}</b></td><td>{{ $booking->layanan?->name }}</td><td>{{ $booking->mitra?->name }}</td><td>{{ $booking->scheduled_at?->format('H:i') }}</td><td><span class="status-pill">{{ str_replace('_',' ',$booking->status) }}</span></td></tr>
        @empty<tr><td colspan="6" class="empty">Belum ada booking hari ini.</td></tr>@endforelse
        </tbody></table>
    </article>
    <article class="modern-panel">
        <div class="modern-head"><h2>Layanan Terlaris</h2><a href="{{ route('admin.dashboard',['section'=>'services']) }}">Lihat Semua</a></div>
        <div class="popular-modern">
            <div class="donut" style="background:conic-gradient(@foreach($charts['popular'] as $i=>$service) {{ $colors[$i%count($colors)] }} {{ $charts['popular']->take($i)->sum('bookings_count')/$popularTotal*100 }}% {{ $charts['popular']->take($i+1)->sum('bookings_count')/$popularTotal*100 }}%{{ !$loop->last?',':'' }} @endforeach)"><div><b>{{ $stats['bookings'] }}</b><span>Booking</span></div></div>
            <div class="legend">@foreach($charts['popular'] as $i=>$service)<div><i style="background:{{ $colors[$i%count($colors)] }}"></i><span>{{ $service->name }}</span><b>{{ $service->bookings_count }} ({{ number_format($service->bookings_count/$popularTotal*100,1) }}%)</b></div>@endforeach</div>
        </div>
    </article>
</section>

<section class="mini-stats">
    @foreach([['User Baru (Bulan Ini)',$stats['new_users'],'purple'],['Mitra Baru (Bulan Ini)',$stats['new_mitras'],'green-icon'],['Pelayan Baru (Bulan Ini)',$stats['new_pelayans'],'orange-icon'],['Booking Hari Ini',$stats['today'],'blue-icon']] as $mini)
    <article><div class="hero-icon {{ $mini[2] }}">+</div><span>{{ $mini[0] }}</span><strong>{{ $mini[1] }}</strong><small>Data backend terbaru</small></article>
    @endforeach
</section>
