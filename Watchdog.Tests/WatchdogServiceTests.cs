using Xunit;
using Microsoft.Extensions.Logging;
using Moq;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace Watchdog.Tests
{
    public class WatchdogServiceTests
    {
        private readonly Mock<ILogger<WatchdogService>> _mockLogger;
        private readonly string _testDirectory;

        public WatchdogServiceTests()
        {
            _mockLogger = new Mock<ILogger<WatchdogService>>();
            _testDirectory = Path.Combine(Path.GetTempPath(), "watchdog_test");
        }

        [Fact]
        public async Task ExecuteAsync_WithValidPath_StartsWatcher()
        {
            // Arrange
            Directory.CreateDirectory(_testDirectory);
            var service = new WatchdogService(_mockLogger.Object);
            var cts = new CancellationTokenSource();

            try
            {
                // Act
                var task = service.ExecuteAsync(cts.Token);
                await Task.Delay(100); // Allow service to initialize

                // Assert
                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("WATCHDOG SERVICE START")),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception, string>>()),
                    Times.Once);

                cts.Cancel();
                await task;
            }
            finally
            {
                if (Directory.Exists(_testDirectory))
                    Directory.Delete(_testDirectory, true);
            }
        }

        [Fact]
        public async Task ExecuteAsync_WithInvalidPath_LogsError()
        {
            // Arrange
            var invalidPath = Path.Combine(Path.GetTempPath(), "nonexistent_" + Guid.NewGuid());
            var service = new WatchdogService(_mockLogger.Object);
            var cts = new CancellationTokenSource();

            // Act
            var task = service.ExecuteAsync(cts.Token);
            cts.Cancel();
            await task;

            // Assert
            _mockLogger.Verify(
                x => x.Log(
                    LogLevel.Error,
                    It.IsAny<EventId>(),
                    It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("Path not found")),
                    It.IsAny<Exception>(),
                    It.IsAny<Func<It.IsAnyType, Exception, string>>()),
                Times.Once);
        }

        [Fact]
        public void FileSystemWatcher_OnFileCreated_LogsCreateEvent()
        {
            // Arrange
            Directory.CreateDirectory(_testDirectory);
            var testFile = Path.Combine(_testDirectory, "test.txt");
            var service = new WatchdogService(_mockLogger.Object);

            try
            {
                // Act
                File.WriteAllText(testFile, "test content");

                // Wait for events to be processed
                Thread.Sleep(500);

                // Assert
                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("[CREATE]")),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception, string>>()),
                    Times.AtLeastOnce);
            }
            finally
            {
                if (File.Exists(testFile))
                    File.Delete(testFile);
                if (Directory.Exists(_testDirectory))
                    Directory.Delete(_testDirectory, true);
            }
        }

        [Fact]
        public void FileSystemWatcher_OnFileModified_LogsChangeEvent()
        {
            // Arrange
            Directory.CreateDirectory(_testDirectory);
            var testFile = Path.Combine(_testDirectory, "test.txt");
            File.WriteAllText(testFile, "initial");
            var service = new WatchdogService(_mockLogger.Object);

            try
            {
                // Act
                File.WriteAllText(testFile, "modified");
                Thread.Sleep(500);

                // Assert
                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("[CHANGE]")),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception, string>>()),
                    Times.AtLeastOnce);
            }
            finally
            {
                if (File.Exists(testFile))
                    File.Delete(testFile);
                if (Directory.Exists(_testDirectory))
                    Directory.Delete(_testDirectory, true);
            }
        }

        [Fact]
        public void FileSystemWatcher_OnFileDeleted_LogsDeleteEvent()
        {
            // Arrange
            Directory.CreateDirectory(_testDirectory);
            var testFile = Path.Combine(_testDirectory, "test.txt");
            File.WriteAllText(testFile, "content");
            var service = new WatchdogService(_mockLogger.Object);

            try
            {
                // Act
                File.Delete(testFile);
                Thread.Sleep(500);

                // Assert
                _mockLogger.Verify(
                    x => x.Log(
                        LogLevel.Information,
                        It.IsAny<EventId>(),
                        It.Is<It.IsAnyType>((v, t) => v.ToString().Contains("[DELETE]")),
                        It.IsAny<Exception>(),
                        It.IsAny<Func<It.IsAnyType, Exception, string>>()),
                    Times.AtLeastOnce);
            }
            finally
            {
                if (Directory.Exists(_testDirectory))
                    Directory.Delete(_testDirectory, true);
            }
        }

        [Fact]
        public void Dispose_CleansUpWatcher()
        {
            // Arrange
            Directory.CreateDirectory(_testDirectory);
            var service = new WatchdogService(_mockLogger.Object);

            // Act
            service.Dispose();

            // Assert - No exception should be thrown
            // Dispose is idempotent
            service.Dispose();
        }
    }
}
