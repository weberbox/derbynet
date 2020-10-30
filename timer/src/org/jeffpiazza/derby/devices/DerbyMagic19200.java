package org.jeffpiazza.derby.devices;

import jssc.SerialPort;
import jssc.SerialPortException;
import org.jeffpiazza.derby.serialport.SerialPortWrapper;

public class DerbyMagic19200 extends DerbyMagicDevice {
  public DerbyMagic19200(SerialPortWrapper portWrapper) {
    super(portWrapper);
  }

  @Override
  public boolean canBeIdentified() {
    return false;
  }

  public static String toHumanString() {
    return "Derby Magic timer (force 19200 baud)";
  }

  @Override
  public boolean probe() throws SerialPortException {
    return probeAtSpeed(SerialPort.BAUDRATE_19200);
  }

}
