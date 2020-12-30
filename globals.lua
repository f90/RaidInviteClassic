local addonName, RIC = ...
-- Author      : Daniel Stoller

RIC._Version = GetAddOnMetadata(addonName,"Version")

-- MODULES
RIC._Guild_Browser = {}
RIC._Roster_Browser = {}
RIC._Roster_Manager = {}
RIC._Codewords_Handler = {}
RIC._Guild_Manager = {}
RIC._Durability_Manager = {}
RIC._RIC_Chat_Manager = {}
RIC._Group_Manager = {}
RIC._Import_Manager = {}

RIC._UpdateInterval = 1.0
RIC._ChatString = "[RIC]:"