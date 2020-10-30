package org.jeffpiazza.derby.devices;

import java.util.ArrayList;
import java.util.List;
import org.jeffpiazza.derby.Message;

import java.util.regex.*;
import jssc.SerialPortException;
import org.jeffpiazza.derby.serialport.SerialPortWrapper;

public class TimerDeviceUtils {
  private static final Pattern finishPattern = Pattern.compile(
      "([A-F]=(\\d\\.\\d+).?)( [A-F]=(\\d\\.\\d+).?)*$");
  private static final Pattern singleLanePattern = Pattern.compile(
      "([A-F])=(\\d\\.\\d+)([^ ]?)");
  private static final Pattern zeroesPattern = Pattern.compile("^0\\.0+$");

  // Each island of carriage-return and/or newlines yields a pair of integers
  // in the list: the index of the first cr/nl character, and the index of the
  // first non-cr/nl character that follows.
  public static List<Integer> lineBoundaries(String line) {
    List<Integer> results = new ArrayList<Integer>();
    int i = 0;
    while (i < line.length()) {
      if (line.charAt(i) == '\n' || line.charAt(i) == '\r') {
        results.add(i);
        int j = i + 1;
        while (j < line.length()
            && (line.charAt(j) == '\n' || line.charAt(j) == '\r')) {
          ++j;
        }
        results.add(j);
        i = j + 1;
      } else {
        ++i;
      }
    }
    return results;
  }

  public static class SplittingDetector implements SerialPortWrapper.Detector {
    public SplittingDetector(SerialPortWrapper.Detector inner) {
      this.inner = inner;
    }

    @Override
    public String apply(String buffer) throws SerialPortException {
      List<Integer> boundaries = lineBoundaries(buffer);
      String[] lines = new String[boundaries.size() / 2 + 1];
      int cap = 0;
      int buffer_index = 0;
      for (int i = 0; i < boundaries.size() / 2; ++i) {
        String line = buffer.substring(buffer_index, boundaries.get(2 * i));
        lines[i] = inner.apply(line);
        cap += lines[i].length()
            + boundaries.get(2 * i + 1) - boundaries.get(2 * i);
        buffer_index = boundaries.get(2 * i + 1);
      }
      lines[boundaries.size() / 2] = inner.apply(buffer.substring(buffer_index));
      cap += lines[boundaries.size() / 2].length();
      StringBuilder builder = new StringBuilder(cap);
      for (int i = 0; i < boundaries.size() / 2; ++i) {
        builder.append(lines[i])
            .append(buffer.substring(boundaries.get(2 * i),
                                     boundaries.get(2 * i + 1)));
      }
      builder.append(lines[boundaries.size() / 2]);
      return builder.toString();
    }

    private SerialPortWrapper.Detector inner;
  }

  // Returns either a Matcher that successfully matched within line, or null.
  public static Matcher matchedCommonRaceResults(String line) {
    Matcher m = finishPattern.matcher(line);
    if (m.find()) {
      return m;
    }
    return null;
  }

  // In a specified (matched) range from line (as determined by
  // matchedCommonRaceResult, above), extracts the individual lane results.
  public static Message.LaneResult[] extractResults(String line, int start,
                                                    int end, int nlanes) {
    Message.LaneResult[] results = new Message.LaneResult[nlanes];
    Matcher m = singleLanePattern.matcher(line);
    for (int i = start; i < end && m.find(i); i = m.end() + 1) {
      int index = m.group(1).charAt(0) - 'A';
      results[index] = new Message.LaneResult();
      results[index].time = m.group(2);
      if (m.group(3).length() > 0) {
        results[index].place = m.group(3).charAt(0) - '!' + 1;
      }
    }

    return results;
  }

  public static Message.LaneResult[] parseCommonRaceResult(String line,
                                                           int nlanes) {
    Matcher m = finishPattern.matcher(line);
    if (m.matches()) {
      Message.LaneResult[] results = new Message.LaneResult[nlanes];
      m = singleLanePattern.matcher(line);
      for (int i = 0; i < line.length() && m.find(i); i = m.end() + 1) {
        int index = m.group(1).charAt(0) - 'A';
        results[index] = new Message.LaneResult();
        results[index].time = m.group(2);
        if (m.group(3).length() > 0) {
          results[index].place = m.group(3).charAt(0) - '!' + 1;
        }
      }

      return results;
    }
    return null;
  }

  public static Message.LaneResult[] zeroesToNines(Message.LaneResult[] results) {
    for (Message.LaneResult r : results) {
      if (r != null && r.time != null) {
        Matcher m = zeroesPattern.matcher(r.time);
        if (m.find()) {
          r.time = r.time.replace('0', '9');
        }
      }
    }
    return results;
  }

  public static void addOneLaneResult(int lane, String time, int place,
                                      ArrayList<Message.LaneResult> results) {
    if (results.size() < lane) {
      results.ensureCapacity(lane);
      while (results.size() < lane) {
        results.add(null);
      }
    }
    results.set(lane - 1, new Message.LaneResult());
    ((Message.LaneResult) results.get(lane - 1)).place = (1 + place);
    ((Message.LaneResult) results.get(lane - 1)).time = time;
  }
}
