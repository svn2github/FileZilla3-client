#include "FileZilla.h"
#include "aboutdialog.h"
#include "buildinfo.h"
#include <wx/hyperlink.h>

BEGIN_EVENT_TABLE(CAboutDialog, wxDialogEx)
EVT_BUTTON(XRCID("wxID_OK"), CAboutDialog::OnOK)
END_EVENT_TABLE();

bool CAboutDialog::Create(wxWindow* parent)
{
	if (!Load(parent, _T("ID_ABOUT")))
		return false;

	XRCCTRL(*this, "ID_URL", wxHyperlinkCtrl)->SetLabel(_T("http://filezilla-project.org"));

	XRCCTRL(*this, "ID_COPYRIGHT", wxStaticText)->SetLabel(_T("Copyright (C) 2004-2007  Tim Kosse"));

	wxString version = CBuildInfo::GetVersion();
	if (CBuildInfo::GetBuildType() == _T("nightly"))
		version += _T("-nightly");
	if (!SetLabel(XRCID("ID_VERSION"), version))
		return false;

	wxStaticText* pHost = XRCCTRL(*this, "ID_HOST", wxStaticText);
	if (!pHost)
		return false;

	wxStaticText* pHostDesc = XRCCTRL(*this, "ID_HOST_DESC", wxStaticText);
	if (!pHostDesc)
		return false;

	wxString host = CBuildInfo::GetHostname();
	if (host == _T(""))
	{
		pHost->Hide();
		pHostDesc->Hide();
	}
	else
		pHost->SetLabel(host);

	wxStaticText* pBuild = XRCCTRL(*this, "ID_BUILD", wxStaticText);
	if (!pBuild)
		return false;

	wxStaticText* pBuildDesc = XRCCTRL(*this, "ID_BUILD_DESC", wxStaticText);
	if (!pBuildDesc)
		return false;

	wxString build = CBuildInfo::GetBuildSystem();
	if (build == _T(""))
	{
		pBuild->Hide();
		pBuildDesc->Hide();
	}
	else
		pBuild->SetLabel(build);

	if (!SetLabel(XRCID("ID_BUILDDATE"), CBuildInfo::GetBuildDateString()))
		return false;

	if (!SetLabel(XRCID("ID_COMPILEDWITH"), CBuildInfo::GetCompiler(), 200))
		return false;

	wxStaticText* pCompilerFlags = XRCCTRL(*this, "ID_CFLAGS", wxStaticText);
	if (!pCompilerFlags)
		return false;

	wxStaticText* pCompilerFlagsDesc = XRCCTRL(*this, "ID_CFLAGS_DESC", wxStaticText);
	if (!pCompilerFlagsDesc)
		return false;

	wxString compilerFlags = CBuildInfo::GetCompilerFlags();
	if (compilerFlags == _T(""))
	{
		pCompilerFlags->Hide();
		pCompilerFlagsDesc->Hide();
	}
	else
	{
		WrapText(this, compilerFlags, 200);
		pCompilerFlags->SetLabel(compilerFlags);
	}

	GetSizer()->Fit(this);
	GetSizer()->SetSizeHints(this);

	return true;
}

void CAboutDialog::OnOK(wxCommandEvent& event)
{
	EndModal(wxID_OK);
}

