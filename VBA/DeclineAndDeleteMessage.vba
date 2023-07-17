'Use macro to Decline and Delete calendar messages. I recommend setting this command behind a custom button in the ribbon.  You may select more than one message
'at a time to decline and delete.  The scenario this is most useful for is when you have many organizational meetings you know you will not be attending
'and you want to quickly decline and delete the message without having to open each one.
Public Sub DeclineAndDeleteMessage()
    Dim cAppt As AppointmentItem
    For x = 1 To Application.ActiveExplorer.Selection.Count
        Set cAppt = Application.ActiveExplorer.Selection.item(x).GetAssociatedAppointment(True)
    
        Dim oResponse As MeetingItem
        Set oResponse = cAppt.Respond(olMeetingDeclined, True)
        oResponse.Send
        Application.ActiveExplorer.Selection.item(x).Delete
    Next x

End Sub