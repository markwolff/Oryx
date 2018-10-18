﻿// --------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// --------------------------------------------------------------------------------------------
using System;
using System.IO;
using Xunit;

namespace Microsoft.Oryx.BuildScriptGenerator.Tests
{
    public class LocalSourceRepoTest : IClassFixture<LocalSourceRepoTest.SourceRepoTestFixutre>
    {
        private readonly string _rootDirPath;

        public LocalSourceRepoTest(SourceRepoTestFixutre fixutre)
        {
            _rootDirPath = fixutre.RootDirPath;
        }

        [Fact]
        public void RootPath_ReturnsRootOfTheSourceDirectory()
        {
            // Arrange & Act
            var sourceRepo = new LocalSourceRepo(_rootDirPath);

            // Assert
            Assert.Equal(_rootDirPath, sourceRepo.RootPath);
        }

        [Theory]
        [InlineData("file1.txt")]
        [InlineData("subDir1", "file1.txt")]
        [InlineData("subDir1", "subDir2", "file1.txt")]
        public void FileExists_DoesRelativePathLookupForFiles(params string[] paths)
        {
            // Arrange
            var sourceRepo = new LocalSourceRepo(_rootDirPath);

            // Act
            var exists = sourceRepo.FileExists(paths);

            // Assert
            Assert.True(exists);
        }

        [Fact]
        public void ReadFile_ReturnsConentOfTheFileRequested()
        {
            // Arrange-1
            var sourceRepo = new LocalSourceRepo(_rootDirPath);

            // Act-1
            var exists = sourceRepo.FileExists("subDir1", "subDir2", "file1.txt");

            // Assert-1
            Assert.True(exists);

            // Arrange-2
            var expected = $"file in {Path.Combine(_rootDirPath, "subDir1", "subDir2")}";

            // Act-2
            var content = sourceRepo.ReadFile("subDir1", "subDir2", "file1.txt");

            // Assert-2
            Assert.Equal(expected, content);
        }

        public class SourceRepoTestFixutre : IDisposable
        {
            public SourceRepoTestFixutre()
            {
                RootDirPath = Path.Combine(Path.GetTempPath(), "oryxtests", Guid.NewGuid().ToString());

                Directory.CreateDirectory(RootDirPath);
                File.WriteAllText(Path.Combine(RootDirPath, "file1.txt"), "file content");

                var subDir1 = Path.Combine(RootDirPath, "subDir1");
                Directory.CreateDirectory(subDir1);
                File.WriteAllText(Path.Combine(subDir1, "file1.txt"), $"file in {subDir1}");

                var subDir2 = Path.Combine(subDir1, "subDir2");
                Directory.CreateDirectory(subDir2);
                File.WriteAllText(Path.Combine(subDir2, "file1.txt"), $"file in {subDir2}");
            }

            public string RootDirPath { get; }

            public void Dispose()
            {
                if (Directory.Exists(RootDirPath))
                {
                    try
                    {
                        Directory.Delete(RootDirPath, recursive: true);
                    }
                    catch
                    {
                        // Do not throw in dispose
                    }
                }
            }
        }
    }
}
