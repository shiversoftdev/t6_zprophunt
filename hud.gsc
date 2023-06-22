createShader(shader, align, relative, x, y, width, height, color, alpha, sort)
{
    hud = newClientHudElem(self);
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
	hud setParent(level.uiParent);
    hud setShader(shader, width, height);
	hud setPoint(align, relative, x, y);
	hud.hideWhenInMenu = true;
	hud.archived = false;
    return hud;
}

drawShader(shader, x, y, width, height, color, alpha, sort, allclients)
{
	hud = undefined;
	if( isDefined( allclients ) )
		hud = newHudElem();
	else
   		hud = newClientHudElem(self);
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    hud setParent(level.uiParent);
    hud setShader(shader, width, height);
    hud.x = x;
    hud.y = y;
	hud.hideWhenInMenu = true;
	hud.archived = false;
    return hud;
}

drawText(text, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort)
{
	hud = self createFontString(font, fontScale);
    hud setPoint(align, relative, x, y);
	hud.color = color;
	hud.alpha = alpha;
	hud.glowColor = glowColor;
	hud.glowAlpha = glowAlpha;
	hud.sort = sort;
	hud.alpha = alpha;
	hud setText(text);
	if(text == "SInitialization")
		hud.foreground = true;
	hud.hideWhenInMenu = true;
	hud.archived = false;
	return hud;
}

drawText2(text, font, fontScale, x, y, color, alpha, glowColor, glowAlpha, sort, allclients)
{
	if (!isDefined(allclients))
		allclients = false;
	if (!allclients)
		hud = self createFontString(font, fontScale);
	else
		hud = level createServerFontString(font, fontScale);
    hud setText(text);
    hud.x = x;
	hud.y = y;
	hud.color = color;
	hud.alpha = alpha;
	hud.glowColor = glowColor;
	hud.glowAlpha = glowAlpha;
	hud.sort = sort;
	hud.alpha = alpha;
	return hud;
}

drawSVT(text, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort)
{
	hud = createServerFontString(font, fontScale);
    hud setPoint(align, relative, x, y);
	hud.color = color;
	hud.alpha = alpha;
	hud.glowColor = glowColor;
	hud.glowAlpha = glowAlpha;
	hud.sort = sort;
	hud.alpha = alpha;
	hud setText(text);
	if(text == "SInitialization")
		hud.foreground = true;
	hud.hideWhenInMenu = true;
	hud.archived = false;
	return hud;
}

sSetText( svar )
{
	self SetText( svar );
	level.SENTINEL_CURRENT_OVERFLOW_COUNTER++;
	if(level.SENTINEL_CURRENT_OVERFLOW_COUNTER > level.SENTINEL_MIN_OVERFLOW_THRESHOLD)
	{
		level notify( "SENTINEL_OVERFLOW_BEGIN_WATCH" );
	}
}

drawValue(value, font, fontScale, align, relative, x, y, color, alpha, glowColor, glowAlpha, sort)
{
	hud = createServerFontString(font, fontScale);
    hud setPoint( align, relative, x, y );
	hud.color = color;
	hud.alpha = alpha;
	hud.glowColor = glowColor;
	hud.glowAlpha = glowAlpha;
	hud.sort = sort;
	hud.alpha = alpha;
	hud setValue(value);
	hud.foreground = true;
	hud.hideWhenInMenu = true;
	return hud;
}

