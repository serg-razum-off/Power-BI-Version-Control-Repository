using System;
using System.Collections;
using System.Collections.Generic;

namespace PowerBI
{
    public class ReportSection
    {
        string sectionGuid = Guid.NewGuid().ToString().Split('-')[0];
        public ReportSection()
        {
            displayName = "ReportPage" + sectionGuid;
            displayOption = 1;
            height = 720;
            name = "ReportSection" + sectionGuid;
            ordinal = 0;
            width = 1280;
        }
        public ReportSection(string _displayName, int _ordinal)
        {
            displayName = _displayName;
            displayOption = 1;
            height = 720;
            name = "ReportSection" + sectionGuid;
            ordinal = _ordinal;
            width = 1280;
        }

        public string displayName { get; set; }
        public int displayOption { get; set; }
        public int height { get; set; }
        public string name { get; set; }
        public int ordinal { get; set; }
        public int width { get; set; }
    }
}