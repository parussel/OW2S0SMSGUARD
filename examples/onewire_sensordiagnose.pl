use strict;
use warnings;
use utf8;

our %defs;

sub OneWireSensordiagnose_Escape {
  my ($value) = @_;
  $value = '' if !defined $value;
  $value =~ s/&/&amp;/g;
  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;
  $value =~ s/"/&quot;/g;
  $value =~ s/'/&#39;/g;
  return $value;
}

sub OneWireSensordiagnose_Value {
  my ($name, $reading) = @_;
  my $missing = '__OW_MISSING__';
  my $value = ReadingsVal($name, $reading, $missing);
  return undef if !defined $value || $value eq $missing || $value eq '';
  return $value;
}

sub OneWireSensordiagnose_CountCell {
  my ($value, $severity) = @_;
  return '<td class="ow-cell"><span class="ow-badge ow-neutral">–</span></td>' if !defined $value;
  my $number = $value =~ /^-?\d+(?:\.\d+)?$/ ? 0 + $value : undef;
  my $class = !defined $number || $number == 0 ? 'ow-neutral' : $severity;
  return '<td class="ow-cell"><span class="ow-badge '.$class.'">'.OneWireSensordiagnose_Escape($value).'</span></td>';
}

sub OneWireSensordiagnose_Html {
  my @sensors = grep {
    ($defs{$_}{TYPE} // '') eq 'OW2S0SMSGUARD' && ($defs{$_}{addr} // '') ne 'master'
  } keys %defs;
  @sensors = sort {
    lc(AttrVal($a, 'alias', $a)) cmp lc(AttrVal($b, 'alias', $b))
  } @sensors;

  my ($ok, $confirming, $fault) = (0, 0, 0);
  my $rows = '';
  for my $name (@sensors) {
    my $alias = AttrVal($name, 'alias', $name);
    my $status = OneWireSensordiagnose_Value($name, 'plausibilityStatus');
    my $anomaly = OneWireSensordiagnose_Value($name, 'plausibilityAnomalyCount');
    my $pending = OneWireSensordiagnose_Value($name, 'plausibilityPendingCount');
    my $rejected = OneWireSensordiagnose_Value($name, 'plausibilityRejectedCount');
    my $last = OneWireSensordiagnose_Value($name, 'plausibilityLastAnomaly');

    my ($status_label, $status_class) = ('–', 'ow-missing');
    if (defined $status && $status eq 'ok') {
      ($status_label, $status_class) = ('OK', 'ow-ok'); $ok++;
    } elsif (defined $status && $status eq 'confirming') {
      ($status_label, $status_class) = ('Bestätigung', 'ow-alert'); $confirming++;
    } elsif (defined $status && $status eq 'fault') {
      ($status_label, $status_class) = ('Fehler', 'ow-fault'); $fault++;
    } else {
    }

    my $last_cell = defined $last
      ? '<td class="ow-last"><span class="ow-badge ow-warn">'.OneWireSensordiagnose_Escape($last).'</span></td>'
      : '<td class="ow-last"><span class="ow-badge ow-neutral">–</span></td>';
    $rows .= '<tr data-sensor="'.OneWireSensordiagnose_Escape($name).'"><td class="ow-name">'.
      OneWireSensordiagnose_Escape($alias).'<div>'.OneWireSensordiagnose_Escape($name).'</div></td>'.
      '<td><span class="ow-status '.$status_class.'">'.OneWireSensordiagnose_Escape($status_label).'</span></td>'.
      OneWireSensordiagnose_CountCell($anomaly, 'ow-warn').
      OneWireSensordiagnose_CountCell($pending, 'ow-alert').
      OneWireSensordiagnose_CountCell($rejected, 'ow-fault').$last_cell.'</tr>';
  }

  return '<style>
    #content table[id="TYPE_01 Heizungsdiagnose"],#content table[id="TYPE_02 Raumdiagnose Erdgeschoss"],#content table[id="TYPE_03 Raumdiagnose Obergeschoss"],#content table[id="TYPE_04 - Heizungsservice"],#content table[id="TYPE_05 - OneWire-Sensordiagnose"],#content table[id="TYPE_06 - Betriebswissen"]{width:1000px!important;max-width:100%}
    .ow-board{width:1000px;max-width:100%;box-sizing:border-box;padding:10px 18px;background:#f5f7fa;color:#59616d}
    .ow-title{font-size:18px;font-weight:bold;letter-spacing:.04em;margin-bottom:8px}
    .ow-summary{display:flex;gap:10px;flex-wrap:wrap;margin:6px 0 12px}.ow-summary span{padding:5px 10px;border-radius:12px;font-weight:bold}
    .ow-board table{width:100%;border-collapse:collapse}.ow-board th{text-align:left;border-bottom:1px solid #7d8794;padding:7px}
    .ow-board td{border-bottom:1px solid #dde2e8;padding:7px;vertical-align:middle}.ow-name{font-weight:bold}.ow-name div{font-weight:normal;font-size:11px;color:#8a929d}
    .ow-cell{text-align:center}.ow-status,.ow-badge{display:inline-block;min-width:42px;text-align:center;padding:2px 7px;border-radius:10px;font-size:11px;font-weight:bold;box-sizing:border-box}.ow-status{min-width:78px}
    .ow-ok{background:#2e8b3c;color:#fff}.ow-neutral{background:#777;color:#fff}.ow-warn{background:#ffb321;color:#2c2c2c}.ow-alert{background:#e47718;color:#fff}.ow-fault{background:#c92727;color:#fff}.ow-missing{background:#777;color:#fff}
    .ow-last{white-space:nowrap;text-align:center}.ow-board footer{margin-top:9px;color:#7c8490;font-size:12px}
  </style><section class="ow-board"><div class="ow-title">05 OneWire-Sensordiagnose</div>'.
    '<div class="ow-summary"><span class="ow-ok">Sensoren: '.scalar(@sensors).'</span><span class="ow-ok">Aktuell OK: '.$ok.'</span>'.
    '<span class="ow-alert">Bestätigung: '.$confirming.'</span><span class="ow-fault">Fehler: '.$fault.'</span></div>'.
    '<table><thead><tr><th>Sensor</th><th>Status</th><th>Anomalien</th><th>Bestätigung läuft</th><th>Verworfene Messungen</th><th>Letzte Anomalie</th></tr></thead><tbody>'.
    $rows.'</tbody></table><footer>Grün = unauffällig · Gelb = historische Auffälligkeit · Orange = laufende Bestätigung · Rot = aktueller Fehler</footer></section>';
}

1;
