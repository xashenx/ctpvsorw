/**
 * 
 */
package netTest;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.MissingResourceException;
import java.util.Properties;

/**
 * @author Stefan Guna
 * 
 */
public class Strings {
	private static final String BUNDLE_NAME = "app.properties"; //$NON-NLS-1$

	private static Properties properties;

	public static String getString(String key) {
		if (properties == null) {
			properties = new Properties();
			try {
				properties.load(new FileInputStream(BUNDLE_NAME));
			} catch (Exception e) {
				e.printStackTrace();
				properties = null;
			}
		}
		try {
			return properties.getProperty(key);
		} catch (MissingResourceException e) {
			return '!' + key + '!';
		}
	}
}
