About
=====

Biscuits is a Nim module for better cookie handling.

Differences from cookie module in standard library:
* Better handling of multiple key-value pairs, particularly with regard to creating cookies.
* Supports "max-age" cookie field.
* Better separation of data from cookie special fields.
* Better methods for editing cookies.
* Object-oriented interface, if you like that kind of thing.

Examples:

    # Start with a cookie, represented as a string.
    var cookieExample : string = "username=John Doe; password=notverysecure; expires=Thu, 30 Dec 2015 12:00:00 UTC; path=/; secure"
    
    # Parse the cookie.
    var myBiscuit : Biscuit = parseBiscuit(cookieExample)
    
    # If the password key is set and equal to "notverysecure", set it to something else.
    if myBiscuit.hasKey("password") and myBiscuit.getKey("password") == "notverysecure":
        discard myBiscuit.setKey("password", "reallyshouldbechanged")
    
    # Add a new key to the cookie.
    discard myBiscuit.setKey("userLevel", "admin")
    
    # Try to set the userLevel key to a different value, but don't overwrite if a value is already set.
    discard myBiscuit.setKey("userLevel", "user", overwrite = false)
    echo(myBiscuit.getKey("userLevel")) # still outputs "admin"
    
    # Change the path of the cookie.
    discard myBiscuit.setPath("/nimExample/")
    echo(myBiscuit.getPath()) # ouputs "/nimExample/"
    
    # Format the cookie as a string.
    var cookieStr : string = $myBiscuit;
    echo(cookieStr)
    # outputs "userLevel=admin; username=John Doe; password=reallyshouldbechanged; path=/nimExample/; expires=Thu, 30 Dec 2015 12:00:00 UTC; secure"
    
    # Create a new cookie. Can also be created with a string table, in order to use multiple key-value pairs.
    var newBiscuit : Biscuit = createBiscuit("thisisakey", "thisisavalue", path = "/", maxAge = "300", httpOnly = true)
    echo(newBiscuit.toString(includeName = true))
    # outputs "Set-Cookie: thisisakey=thisisavalue; path=/; max-age=300; HttpOnly"

License
=======

Biscuits is released under the MIT open source license.
