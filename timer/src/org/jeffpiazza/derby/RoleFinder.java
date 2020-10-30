package org.jeffpiazza.derby;

import java.io.IOException;
import org.jeffpiazza.derby.gui.TimerGui;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

// From a server address, tries to make first contact with the web server by
// asking about the available roles.
//
// Usage: Create a new RoleFinder, spawn a new thread to run findRoles().
// Cancel asynchronously by calling cancel(),
// otherwise wait until call to gui.rolesComplete().
public class RoleFinder {
  // serverAddress and session are fixed for the lifetime of the RoleFinder,
  // but gui may be set to null by a cancel() call from another thread.
  String serverAddress;
  TimerGui gui;
  ClientSession session;

  public RoleFinder(String serverAddress, TimerGui timerGui) {
    this.serverAddress = serverAddress;
    this.gui = timerGui;
    this.session = new ClientSession(serverAddress);
  }

  public synchronized String getServerAddress() {
    return serverAddress;
  }

  public ClientSession getSession() {
    return session;
  }

  public synchronized void cancel() {
    this.gui = null;
  }

  // Spawn a new thread to run RoleFinder.findRoles.
  // On success, calls gui.addRole as needed, then gui.rolesComplete(true).
  // On failure, calls gui.rolesComplete(false)
  public void findRoles() {
    boolean succeeded = false;
    try {
      Element roles_result = session.doQueryWithVariations("roles");
      if (roles_result == null) {
        gui.roleFinderFailed(
            "No response, or response not understood (likely wrong URL)");
      } else {
        synchronized (this) {
          serverAddress = session.getBaseUrl();
          gui.setUrl(serverAddress);
        }
        NodeList roles = roles_result.getElementsByTagName("role");
        if (roles.getLength() == 0) {
          NodeList titles = roles_result.getElementsByTagName("title");
          if (titles.getLength() == 1 && titles.item(0).getFirstChild().
              getNodeValue().contains("Set-Up")) {
            // Redirected to the set-up page, because there's no database
            gui.roleFinderFailed("Set up the server database before proceeding");
          } else {
            gui.roleFinderFailed("No roles provided in roles query");
          }
        } else {
          for (int i = 0; i < roles.getLength(); ++i) {
            Element role = (Element) roles.item(i);
            if (!role.getAttribute("timer_message").isEmpty()) {
              gui.addRole(role.getTextContent());
              succeeded = true;
            }
            if (!role.getAttribute("race_control").isEmpty()) {
              gui.addRole(role.getTextContent());
              succeeded = true;
            }
          }
          if (!succeeded) {
            gui.roleFinderFailed("Roles received, but none are suitable.");
          }
        }
      }
    } catch (IOException e) {
      gui.roleFinderFailed(e.getMessage());
      e.printStackTrace();  // TODO
    } finally {
      synchronized (this) {
        if (succeeded && gui != null) {
          gui.rolesComplete();
        }
      }
    }
  }
}
