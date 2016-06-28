if(~exist('sp', 'var'))
    sp = BluetoothPlotter('Weimen''s Robot');
    sp.setTitles({'xAccel', 'yAccel', 'zAccel'});
    sp.setAxisLabels({'Time (s)', 'xAccel (g)', 'yAccel (g)', 'zAccel (g)'});
end
sp.beginPlotting(30);
data = sp.getData();
%delete(sp);

    