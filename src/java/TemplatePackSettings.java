import dev.irisshaders.aperture.api.PackSettings;
import dev.irisshaders.aperture.api.settings.OptionType;
import dev.irisshaders.aperture.api.settings.SettingsManager;
import dev.irisshaders.aperture.api.settings.SettingsScreen;

public class TemplatePackSettings implements PackSettings {

    @Override
    public void createSettings(SettingsManager manager, SettingsScreen screen) {
        screen.option("shadows", OptionType.boolType(true), false);
    }
    
}
