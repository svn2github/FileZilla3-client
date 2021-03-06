#include "FileZilla.h"
#include "loginmanager.h"
#include "filezillaapp.h"

CLoginManager CLoginManager::m_theLoginManager;

bool CLoginManager::GetPassword(CServer &server, bool silent, wxString name /*=_T("")*/, wxString challenge /*=_T("")*/)
{
	wxASSERT(!silent || server.GetLogonType() == ASK);
	wxASSERT(server.GetLogonType() != INTERACTIVE || challenge != _T(""));
	wxASSERT(challenge == _T("") || server.GetLogonType() == INTERACTIVE);

	if (server.GetLogonType() == ASK)
	{
		std::list<t_passwordcache>::const_iterator iter;
		for (iter = m_passwordCache.begin(); iter != m_passwordCache.end(); iter++)
		{
			if (iter->host != server.GetHost())
				continue;
			if (iter->port != server.GetPort())
				continue;
			if (iter->user != server.GetUser())
				continue;
	
			server.SetUser(server.GetUser(), iter->password);
			return true;
		}
	}
	if (silent)
		return false;

	return DisplayDialog(server, name, challenge);
}

bool CLoginManager::DisplayDialog(CServer &server, wxString name, wxString challenge)
{
	wxDialog pwdDlg;
	wxXmlResource::Get()->LoadDialog(&pwdDlg, wxGetApp().GetTopWindow(), _T("ID_ENTERPASSWORD"));
	if (name == _T(""))
	{
		pwdDlg.GetSizer()->Show(XRCCTRL(pwdDlg, "ID_NAMELABEL", wxStaticText), false, true);
		pwdDlg.GetSizer()->Show(XRCCTRL(pwdDlg, "ID_NAME", wxStaticText), false, true);
	}
	else
		XRCCTRL(pwdDlg, "ID_NAME", wxStaticText)->SetLabel(name);
	if (challenge == _T(""))
	{
		pwdDlg.GetSizer()->Show(XRCCTRL(pwdDlg, "ID_CHALLENGELABEL", wxStaticText), false, true);
		pwdDlg.GetSizer()->Show(XRCCTRL(pwdDlg, "ID_CHALLENGE", wxTextCtrl), false, true);
	}
	else
	{
#ifdef __WXMSW__
		challenge.Replace(_T("\n"), _T("\r\n"));
#endif
		XRCCTRL(pwdDlg, "ID_CHALLENGE", wxTextCtrl)->ChangeValue(challenge);
		pwdDlg.GetSizer()->Show(XRCCTRL(pwdDlg, "ID_REMEMBER", wxCheckBox), false, true);
		XRCCTRL(pwdDlg, "ID_CHALLENGE", wxTextCtrl)->SetBackgroundColour(wxSystemSettings::GetColour(wxSYS_COLOUR_BTNFACE));
	}
	XRCCTRL(pwdDlg, "ID_HOST", wxStaticText)->SetLabel(server.FormatHost());
	XRCCTRL(pwdDlg, "ID_USER", wxStaticText)->SetLabel(server.GetUser());
	XRCCTRL(pwdDlg, "wxID_OK", wxButton)->SetId(wxID_OK);
	XRCCTRL(pwdDlg, "wxID_CANCEL", wxButton)->SetId(wxID_CANCEL);
	pwdDlg.GetSizer()->Fit(&pwdDlg);
	pwdDlg.GetSizer()->SetSizeHints(&pwdDlg);
	if (pwdDlg.ShowModal() != wxID_OK)
		return false;

	server.SetUser(server.GetUser(), XRCCTRL(pwdDlg, "ID_PASSWORD", wxTextCtrl)->GetValue());

	if (server.GetLogonType() == ASK && XRCCTRL(pwdDlg, "ID_REMEMBER", wxCheckBox)->GetValue())
	{
		t_passwordcache entry;
		entry.host = server.GetHost();
		entry.port = server.GetPort();
		entry.user = server.GetUser();
		entry.password = server.GetPass();
		m_passwordCache.push_back(entry);
	}

	return true;
}

void CLoginManager::CachedPasswordFailed(const CServer& server)
{
	if (server.GetLogonType() != ASK)
		return;
	
	for (std::list<t_passwordcache>::iterator iter = m_passwordCache.begin(); iter != m_passwordCache.end(); iter++)
	{
		if (iter->host != server.GetHost())
			continue;
		if (iter->port != server.GetPort())
			continue;
		if (iter->user != server.GetUser())
			continue;
	
		m_passwordCache.erase(iter);
		return;
	}
}
