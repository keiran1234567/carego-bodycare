<table>
    <thead><tr><th>Kode</th><th>User</th><th>Layanan / Mitra</th><th>Jadwal</th><th>Total</th><th>Status</th><th>Pembayaran</th><th>Aksi</th></tr></thead>
    <tbody>
    @forelse($items as $booking)
        <tr>
            <td><b>{{ $booking->booking_code }}</b></td>
            <td>{{ $booking->user?->name }}<br>{{ $booking->user?->phone ?: '-' }}</td>
            <td><b>{{ $booking->layanan?->name }}</b><br>{{ $booking->mitra?->name }}</td>
            <td>{{ $booking->scheduled_at?->format('d M Y H:i') }}</td>
            <td class="money">Rp{{ number_format($booking->total_price,0,',','.') }}</td>
            <td><span class="badge">{{ str_replace('_',' ',$booking->status) }}</span></td>
            <td><span class="badge {{ $booking->pembayaran?->status_pembayaran === 'PAID' ? 'green':'yellow' }}">{{ $booking->pembayaran?->status_pembayaran ?: 'BELUM' }}</span></td>
            <td><details><summary>Update Status</summary><form method="post" action="{{ route('admin.bookings.update',$booking) }}">@csrf @method('PATCH')<label>Status<select name="status">@foreach(['DITERIMA_MITRA','DIKIRIM_KE_PELAYAN','DITERIMA_PELAYAN','MENUJU_LOKASI','SEDANG_DIKERJAKAN','SELESAI'] as $status)<option>{{ $status }}</option>@endforeach</select></label><label>Catatan<input name="reason"></label><button>Update</button></form></details></td>
        </tr>
    @empty
        <tr><td colspan="8" class="empty">Belum ada data booking.</td></tr>
    @endforelse
    </tbody>
</table>
