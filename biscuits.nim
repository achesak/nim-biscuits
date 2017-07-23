## Biscuits is a Nim module for better cookie handling.
##
## Differences from cookie module in standard library:
## * Better handling of multiple key-value pairs, particularly with regard to creating cookies.
## * Supports "max-age" cookie field.
## * Better separation of data from cookie special fields.
## * Better methods for editing cookies.
## * Object-oriented interface, if you like that kind of thing.
##
## Examples:
##
## .. code-block:: nimrod
##
##    # Start with a cookie, represented as a string.
##    var cookieExample : string = "username=John Doe; password=notverysecure; expires=Thu, 30 Dec 2015 12:00:00 UTC; path=/; secure"
##
##    # Parse the cookie.
##    var myBiscuit : Biscuit = parseBiscuit(cookieExample)
##
##    # If the password key is set and equal to "notverysecure", set it to something else.
##    if myBiscuit.hasKey("password") and myBiscuit.getKey("password") == "notverysecure":
##        discard myBiscuit.setKey("password", "reallyshouldbechanged")
##
##    # Add a new key to the cookie.
##    discard myBiscuit.setKey("userLevel", "admin")
##
##    # Try to set the userLevel key to a different value, but don't overwrite if a value is already set.
##    discard myBiscuit.setKey("userLevel", "user", overwrite = false)
##    echo(myBiscuit.getKey("userLevel")) # still outputs "admin"
##
##    # Change the path of the cookie.
##    discard myBiscuit.setPath("/nimExample/")
##    echo(myBiscuit.getPath()) # ouputs "/nimExample/"
##
##    # Format the cookie as a string.
##    var cookieStr : string = $myBiscuit;
##    echo(cookieStr)
##    # outputs "userLevel=admin; username=John Doe; password=reallyshouldbechanged; path=/nimExample/; expires=Thu, 30 Dec 2015 12:00:00 UTC; secure"
##
##    # Create a new cookie. Can also be created with a string table, in order to use multiple key-value pairs.
##    var newBiscuit : Biscuit = createBiscuit("thisisakey", "thisisavalue", path = "/", maxAge = "300", httpOnly = true)
##    echo(newBiscuit.toString(includeName = true))
##    # outputs "Set-Cookie: thisisakey=thisisavalue; path=/; max-age=300; HttpOnly"


# Written by Adam Chesak.
# Released under the MIT open source license.


import cookies
import strtabs
import strutils
import times


type
    Biscuit* = ref object
        data* : StringTableRef
        domain : string
        path : string
        expires : string
        maxAge : string
        secure : bool
        httpOnly : bool

    BiscuitError* = object of Exception


proc parseBiscuit*(s : string): Biscuit =
    ## Parses a cookie and returns it as a ``Biscuit`` object.

    var cs : StringTableRef = cookies.parseCookies(s)
    var c : Biscuit = Biscuit()
    c.data = newStringTable(modeCaseSensitive)

    for key, value in cs:

        if key.toLower() == "domain":
            c.domain = value
        elif key.toLower() == "path":
            c.path = value
        elif key.toLower() == "expires":
            c.expires = value
        elif key.toLower() == "max-age":
            c.maxAge = value
        elif key.toLower() == "secure":
            if value.toLower() != "false":
                c.secure = true
            else:
                c.secure = false
        elif key.toLower() == "httponly":
            if value.toLower() != "false":
                c.httpOnly = true
            else:
                c.httpOnly = false
        else:
            c.data[key] = value

    # Sometimes secure and HttpOnly fields don't get set properly in the previous loop.
    # Double check here. Kind of messy but works for now.
    var fields : seq[string] = s.split(";")
    for i in 0..high(fields):
        fields[i] = fields[i].strip(leading = true, trailing = true).toLower()
        if fields[i] == "secure":
            c.secure = true
        if fields[i] == "httponly":
            c.httpOnly = true

    return c


proc createBiscuit*(data : StringTableRef, domain : string = "", path : string = "", expires : string = "",
                  maxAge : string = "", secure : bool = false, httpOnly : bool = false): Biscuit =
    ## Creates a ``Biscuit`` object from the given parameters

    var c : Biscuit = Biscuit(data: data, domain: domain, path: path, expires: expires, maxAge: maxAge,
                            secure: secure, httpOnly: httpOnly)
    return c


proc createBiscuit*(key : string, value : string, domain : string = "", path : string = "", expires : string = "",
                  maxAge : string = "", secure : bool = false, httpOnly : bool = false): Biscuit =
    ## Creates a ``Biscuit`` object from the given parameters

    var c : Biscuit = Biscuit(data: newStringTable(key, value, modeCaseSensitive), domain: domain, path: path, expires: expires, maxAge: maxAge,
                            secure: secure, httpOnly: httpOnly)
    return c


proc toString*(c : Biscuit, includeName : bool = false): string =
    ## Converts the given ``Biscuit`` to a string. If ``includeName`` is set to ``true``, prepends ``Set-Cookie:``.

    var s : string = ""

    if includeName:
        s &= "Set-Cookie: "
    for key, value in c.data:
        s &= key & "=" & value & "; "
    if c.domain != nil and c.domain != "":
        s &= "domain=" & c.domain & "; "
    if c.path != nil and c.path != "":
        s &= "path=" & c.path & "; "
    if c.expires != nil and c.expires != "":
        s &= "expires=" & c.expires & "; "
    if c.maxAge != nil and c.maxAge != "":
        s &= "max-age=" & c.maxAge & "; "
    if c.secure:
        s &= "secure; "
    if c.httpOnly:
        s &= "HttpOnly; "

    s = s.strip(trailing = true)
    if s.endsWith(";"):
        s = s[0..high(s) - 1]

    return s


proc `$`*(c : Biscuit): string =
    ## Converts the given ``Biscuit`` to a string.

    return c.toString()


proc hasKey*(c : Biscuit, key : string): bool =
    ## Returns ``true`` if the given ``Biscuit`` has given data ``key``, and ``false`` otherwise.

    return c.data.hasKey(key)


proc getKey*(c : Biscuit, key : string, defaultValue : string = ""): string =
    ## Gets the value of the ``key`` in the given ``Biscuit``. If the ``key`` has no value associated with it and
    ## a ``defaultValue`` is given, the default value is returned instead.

    if not c.data.hasKey(key):
        return defaultValue
    else:
        return c.data[key]


proc setKey*(c : Biscuit, key : string, value : string, overwrite : bool = true): bool =
    ## Sets the ``key`` to the given ``value. If ``overwrite`` is ``false` and the ``key`` already has a value
    ## associated with it, nothing will be changed.

    # Don't allow reserved fields.
    if key.toLower() in @["domain", "path", "expires", "max-age", "secure", "httponly"]:
        raise newException(BiscuitError, "Key cannot be set to a reserved field.")

    if c.data.hasKey(key) and not overwrite:
        return false
    else:
        c.data[key] = value
        return true


proc clearKeys*(c : Biscuit): seq[string] =
    ## Clears all keys from the given ``Biscuit``.

    var k : seq[string] = @[]
    for key, value in c.data:
        k.add(key)

    c.data.clear(modeCaseSensitive)
    return k


proc hasDomain*(c : Biscuit): bool =
    ## Returns ``true`` if the given ``Biscuit`` has a domain field set, and ``false`` otherwise.

    return c.domain != nil and c.domain != ""


proc getDomain*(c : Biscuit, defaultValue : string = ""): string =
    ## Gets the value of the domain field for the given ``Biscuit``. If no domain field is set and a ``defaultValue`` is given,
    ## the default value is returned instead.

    if c.domain == nil:
        return defaultValue
    else:
        return c.domain


proc setDomain*(c : Biscuit, domain : string): string =
    ## Sets the domain field to the specified value.

    var d : string = c.domain
    c.domain = domain
    return d


proc hasPath*(c : Biscuit): bool =
    ## Returns ``true`` if the given ``Biscuit`` has a path field set, and ``false`` otherwise.

    return c.path != nil and c.path != ""


proc getPath*(c : Biscuit, defaultValue : string = ""): string =
    ## Gets the value of the path field for the given ``Biscuit``. If no path field is set and a ``defaultValue`` is given,
    ## the default value is returned instead.

    if c.path == nil:
        return defaultValue
    else:
        return c.path


proc setPath*(c : Biscuit, path : string): string =
    ## Sets the path field to the specified value.

    var p : string = c.path
    c.path = path
    return p


proc hasExpires*(c : Biscuit): bool =
    ## Returns ``true`` if the given ``Biscuit`` has an expires field set, and ``false`` otherwise.

    return c.expires != nil and c.expires != ""


proc getExpires*(c : Biscuit, defaultValue : string = ""): string =
    ## Gets the value of the expires field for the given ``Biscuit``. If no expires field is set and a ``defaultValue`` is given,
    ## the default value is returned instead.

    if c.expires == nil:
        return defaultValue
    else:
        return c.expires


proc getExpiresTimeInfo*(c : Biscuit): TimeInfo =
    ## Gets the value of the expires field for the given ``Biscuit``. Returns the field as a ``TimeInfo`` object.

    var t : string = c.getExpires()
    return parse(t, "ddd, dd MMM yyyy hh:mm:ss UTC")


proc setExpires*(c : Biscuit, expires : string): string =
    ## Sets the expires field to the specified value.

    var e : string = c.expires
    c.expires = expires
    return e


proc setExpiresTimeInfo*(c : Biscuit, expires : TimeInfo): TimeInfo =
    ## Sets the expires field to the specifiied value.

    var e : TimeInfo = parse(c.expires, "ddd, dd MMM yyyy hh:mm:ss UTC")
    c.expires = format(expires, "ddd, dd MMM yyyy HH:mm:ss UTC")
    return e


proc hasMaxAge*(c : Biscuit): bool =
    ## Returns ``true`` if the given ``Biscuit`` has a max-age field set, and ``false`` otherwise.

    return c.maxAge != nil and c.maxAge != ""


proc getMaxAge*(c : Biscuit, defaultValue : string = ""): string =
    ## Gets the value of the max-age field for the given ``Biscuit``. If no max-age field is set and a ``defaultValue`` is given,
    ## the default value is returned instead.

    if c.maxAge == nil:
        return defaultValue
    else:
        return c.maxAge


proc getMaxAgeTimeInfo*(c : Biscuit): TimeInfo =
    ## Gets the value of the max-age field for the given ``Biscuit``. Returns the field as a ``TimeInfo`` object.

    var t : string = c.getMaxAge()
    return parseFloat(t).fromSeconds().timeToTimeInfo()


proc setMaxAge*(c : Biscuit, maxAge : string): string =
    ## Sets the max-age field to the specified value.

    var m : string = c.maxAge
    c.maxAge = maxAge
    return m


proc setMaxAgeTimeInfo*(c : Biscuit, maxAge : TimeInfo): TimeInfo =
    ## Sets the max-age field to the specifiied value.

    var m : TimeInfo = c.getMaxAgeTimeInfo()
    c.maxAge = int(maxAge.timeInfoToTime().toSeconds()).intToStr()
    return m


proc isSecure*(c : Biscuit): bool =
    ## Returns ``true`` if the secure field of the given ``Biscuit`` is set and true, and ``false`` otherwise.

    return c.secure


proc setSecure*(c : Biscuit, secure : bool): bool =
    ## Sets the secure field to the specified value.

    var s : bool = c.secure
    c.secure = secure
    return s


proc isHttpOnly*(c : Biscuit): bool =
    ## Returns ``true`` if the HttpOnly field of the given ``Biscuit`` is set and true, and ``false`` otherwise.

    return c.httpOnly


proc setHttpOnly*(c : Biscuit, httpOnly : bool): bool =
    ## Sets the HttpOnly field to the specified value.

    var h : bool = c.httpOnly
    c.httpOnly = httpOnly
    return h


proc `[]`*(c : Biscuit, key : string): string =
    ## Shortcut for ``getKey()``.

    return c.getKey(key)


proc `[]=`*(c : Biscuit, key : string, value : string) {.noreturn.} =
    ## Shortcut for ``setKey()``.

    discard c.setKey(key, value)


proc `==`*(c1 : Biscuit, c2 : Biscuit): bool =
    ## Equality operator for ``Biscuit``.

    # Check that the cookie fields are the same.
    if c1.domain != c2.domain:
        return false
    if c1.path != c2.path:
        return false
    if c1.expires != c2.expires:
        return false
    if c1.maxAge != c2.maxAge:
        return false
    if c1.secure != c2.secure:
        return false
    if c1.httpOnly != c2.httpOnly:
        return false

    # Check that the data fields are the same.
    if len(c1.data) != len(c2.data):
        return false
    for key, value in c1.data:
        if not c2.hasKey(key):
            return false
        if value != c2.getKey(key):
            return false
    for key, value in c2.data:
        if not c1.hasKey(key):
            return false
        if value != c1.getKey(key):
            return false

    return true


proc `!=`*(c1 : Biscuit, c2 : Biscuit): bool =
    ## Inequality operator for ``Biscuit``.

    return not (c1 == c2)


iterator pairs*(c : Biscuit): tuple[key : string, value : string] =
    ## Iterates over key-value pairs.

    for key, value in c.data:
        yield (key, value)


iterator keys*(c : Biscuit): string =
    ## Iterates over keys.

    for key in keys(c.data):
        yield key


iterator values*(c : Biscuit): string =
    ## Iterates over values.

    for value in values(c.data):
        yield value
